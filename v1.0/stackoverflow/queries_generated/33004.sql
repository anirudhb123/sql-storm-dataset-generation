WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL  -- Top-level questions

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        r.Level + 1
    FROM Posts p
    JOIN RecursiveCTE r ON p.ParentId = r.PostId  -- Join with answers
)

SELECT 
    u.DisplayName AS Author,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- UpMod votes
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- DownMod votes
    CASE 
        WHEN b.Id IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasBadge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS UserPostRank
FROM RecursiveCTE r
JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN Comments c ON r.PostId = c.PostId
LEFT JOIN Votes v ON r.PostId = v.PostId
LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
LEFT JOIN Posts p ON p.Id = r.PostId
LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
WHERE r.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter by posts created in the last 30 days
GROUP BY 
    u.DisplayName, r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, b.Id
ORDER BY 
    r.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
