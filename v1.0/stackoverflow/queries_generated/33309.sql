WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
RecentVotes AS (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = p.Tags
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    r.PostId,
    r.Title,
    u.DisplayName AS OwnerDisplayName,
    r.Score,
    r.ViewCount,
    COALESCE(v.VoteCount, 0) AS VoteCount,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    (SELECT STRING_AGG(TagName, ', ') FROM TopTags tt WHERE tt.PostCount > 0) AS MostPopularTags
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    RecentVotes v ON r.PostId = v.PostId
WHERE 
    r.Score > 10
    AND r.ViewCount > 100
ORDER BY 
    r.ViewCount DESC, r.Score DESC
LIMIT 10;
