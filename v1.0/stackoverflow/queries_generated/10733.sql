-- Performance benchmarking query to analyze post statistics and their associated user activity
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Adjust this date for benchmarking period
    GROUP BY 
        p.Id, u.Id
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.OwnerReputation,
    ps.OwnerDisplayName,
    ts.TagName,
    ts.PostCount
FROM 
    PostStats ps
LEFT JOIN 
    TagStats ts ON ps.PostId = ts.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;  -- Limit the results to the top 100 posts for performance measurement
