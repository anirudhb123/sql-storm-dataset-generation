WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id AS PostId, 
        ParentId, 
        Title, 
        ViewCount, 
        Score, 
        1 as Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.ViewCount,
    ph.Score,
    ph.Level,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId), 0) AS CommentCount,
    U.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 3) AS DownVotes,
    CASE
        WHEN ph.OwnerDisplayName IS NULL THEN 'Community User'
        ELSE ph.OwnerDisplayName
    END AS PostOwner,
    (SELECT STRING_AGG(TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)) AS TagList
FROM 
    PostHierarchy ph
LEFT JOIN 
    Users U ON ph.OwnerUserId = U.Id
WHERE 
    ph.ViewCount > 100
ORDER BY 
    ph.Score DESC, 
    ph.ViewCount DESC
LIMIT 100;

This query is designed to extract a detailed view of posts, starting with questions, and their hierarchical relationships. It uses a recursive CTE to fetch questions and their answers, counts comments, absolute upvotes, and downvotes, and ensures that community posts are accurately labeled. The fetched posts are filtered by minimum view counts and sorted by score and view counts for performance benchmarking.
