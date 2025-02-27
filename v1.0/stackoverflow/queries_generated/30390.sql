WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Start with root posts

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags 
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        DENSE_RANK() OVER (ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
)

SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.EditCount,
    tp.Tags,
    COALESCE(rp.Level, 0) AS PostLevel,
    ra.ActivityRank
FROM 
    Posts p
LEFT JOIN 
    PostStats ps ON p.Id = ps.PostId
LEFT JOIN 
    TaggedPosts tp ON p.Id = tp.PostId
LEFT JOIN 
    RecursivePostHierarchy rp ON p.Id = rp.Id
LEFT JOIN 
    RecentActivity ra ON p.Id = ra.PostId
WHERE 
    p.PostTypeId = 1 -- Only Questions
    AND (ps.UpVotes - ps.DownVotes) > 10 -- Popularity criteria
    AND ra.ActivityRank <= 5 -- Only the last 5 active posts
ORDER BY 
    p.LastActivityDate DESC;
