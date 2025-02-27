-- Performance Benchmarking SQL Query

-- 1. Retrieve the count of posts per type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- 2. Calculate average Reputation of users who own posts.
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.OwnerUserId IS NOT NULL;

-- 3. Count the number of votes per post along with their types.
SELECT 
    p.Title,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    p.Title, vt.Name
ORDER BY 
    VoteCount DESC;

-- 4. Retrieve the latest closed posts with their close reasons.
SELECT 
    p.Title,
    ph.CreationDate AS ClosedDate,
    crt.Name AS CloseReason
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Considering Close and Reopen events
ORDER BY 
    ClosedDate DESC
LIMIT 10;

-- 5. Get the most popular tags based on the post count.
SELECT 
    t.TagName,
    COUNT(p.Id) AS PostCount
FROM 
    Tags t
LEFT JOIN 
    Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC
LIMIT 10;

-- 6. Analyze user contributions based on the number of posts created.
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;

-- 7. Get the last edited posts with their editors' information.
SELECT 
    p.Title,
    p.LastEditDate,
    u.DisplayName AS LastEditor
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.LastEditorUserId = u.Id
ORDER BY 
    LastEditDate DESC
LIMIT 10;
