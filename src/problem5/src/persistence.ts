import { PrismaClient } from '@prisma/client';

export interface Resource {
    id: string;
    name: string;
    details: string;
    createdAt: string;
    updatedAt: string;
}

export interface ResourceInput {
    name: string;
    details?: string;
}

const prisma = new PrismaClient();

export async function migrate(): Promise<void> {
    // Prisma handles migrations automatically
    // This function is kept for compatibility
}

export async function createResource(input: ResourceInput): Promise<Resource> {
    const resource = await prisma.resource.create({
        data: {
            name: input.name,
            details: input.details ?? ''
        }
    });
    return mapResource(resource);
}

export async function listResources(params: { q?: string; limit: number; offset: number }): Promise<{ total: number; items: Resource[] }> {
    const { q, limit, offset } = params;
    
    const where = q && q.trim() !== '' ? {
        OR: [
            { name: { contains: q, mode: 'insensitive' as const } },
            { details: { contains: q, mode: 'insensitive' as const } }
        ]
    } : {};

    const [items, total] = await Promise.all([
        prisma.resource.findMany({
            where,
            orderBy: { id: 'asc' },
            skip: offset,
            take: limit
        }),
        prisma.resource.count({ where })
    ]);

    return { total, items: items.map(mapResource) };
}

export async function getResource(id: string): Promise<Resource | null> {
    const resource = await prisma.resource.findUnique({
        where: { id: parseInt(id, 10) }
    });
    return resource ? mapResource(resource) : null;
}

export async function updateResource(id: string, input: Partial<ResourceInput>): Promise<Resource | null> {
    const existing = await prisma.resource.findUnique({
        where: { id: parseInt(id, 10) }
    });
    
    if (!existing) return null;

    const updateData: { name?: string; details?: string } = {};
    if (typeof input.name === 'string' && input.name.trim() !== '') {
        updateData.name = input.name.trim();
    }
    if (typeof input.details === 'string') {
        updateData.details = input.details;
    }

    const resource = await prisma.resource.update({
        where: { id: parseInt(id, 10) },
        data: updateData
    });

    return mapResource(resource);
}

export async function deleteResource(id: string): Promise<Resource | null> {
    try {
        const resource = await prisma.resource.delete({
            where: { id: parseInt(id, 10) }
        });
        return mapResource(resource);
    } catch (error) {
        return null;
    }
}

function mapResource(resource: any): Resource {
    return {
        id: String(resource.id),
        name: resource.name,
        details: resource.details,
        createdAt: resource.createdAt.toISOString(),
        updatedAt: resource.updatedAt.toISOString()
    };
}


