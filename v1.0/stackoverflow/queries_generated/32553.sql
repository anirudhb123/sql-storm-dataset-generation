WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        PostTypeId,
        ParentId,
        Title,
        Score,
        CreationDate,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.PostTypeId,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
)

, PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score AS PostScore,
    p.ViewCount,
    rph.Level AS HierarchyLevel,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users U ON p.OwnerUserId = U.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.Id
LEFT JOIN 
    PostVoteSummary vs ON p.Id = vs.PostId
LEFT JOIN 
    STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag_arr 
    ON TRUE 
LEFT JOIN 
    Tags t ON t.TagName = ANY(tag_arr)
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only recent posts
GROUP BY 
    p.Id, p.Title, p.Score, p.ViewCount, rph.Level, U.DisplayName, U.Reputation, vs.UpVotes, vs.DownVotes
ORDER BY 
    PostScore DESC, PostId
LIMIT 100;
