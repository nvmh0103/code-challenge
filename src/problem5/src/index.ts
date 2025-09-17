import express, { Request, Response } from 'express';
import { migrate, createResource, deleteResource, getResource, listResources, updateResource, Resource, ResourceInput } from './persistence';

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Create resource
app.post('/resources', async (req: Request, res: Response) => {
    const body = req.body as ResourceInput;
    if (!body || typeof body.name !== 'string' || body.name.trim() === '') {
        return res.status(400).json({ error: 'name is required' });
    }
    const resource = await createResource({ name: body.name.trim(), details: body.details ?? '' });
    return res.status(201).json(resource);
});

// List resources with basic filters and pagination
app.get('/resources', async (req: Request, res: Response) => {
    const { q, limit = '20', offset = '0' } = req.query as Record<string, string>;
    const off = Math.max(0, parseInt(offset, 10) || 0);
    const lim = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
    const result = await listResources({ q, limit: lim, offset: off });
    return res.json({ total: result.total, limit: lim, offset: off, items: result.items });
});

// Get details
app.get('/resources/:id', async (req: Request, res: Response) => {
    const found = await getResource(req.params.id);
    if (!found) return res.status(404).json({ error: 'Not found' });
    return res.json(found);
});

// Update resource
app.put('/resources/:id', async (req: Request, res: Response) => {
    const body = req.body as Partial<ResourceInput>;
    const updated = await updateResource(req.params.id, body);
    if (!updated) return res.status(404).json({ error: 'Not found' });
    return res.json(updated);
});

// Delete resource
app.delete('/resources/:id', async (req: Request, res: Response) => {
    const deleted = await deleteResource(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Not found' });
    return res.json(deleted);
});

app.get('/', (_req: Request, res: Response) => {
    res.send('Problem 5 CRUD Server is running');
});

// Ensure DB is ready, then start
migrate().then(() => {
    app.listen(PORT, () => {
        // eslint-disable-next-line no-console
        console.log(`Server listening on http://localhost:${PORT}`);
    });
}).catch((err) => {
    // eslint-disable-next-line no-console
    console.error('Failed to migrate database:', err);
    process.exit(1);
});


