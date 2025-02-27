WITH RecursivePostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        1 AS Level
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  -- Considering only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        rd.Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePostDetails rd ON rd.PostId = p.ParentId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AvgBounty,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    ROW_NUMBER() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.CreationDate DESC) AS RankByOwner
FROM RecursivePostDetails pd
LEFT JOIN Comments c ON pd.PostId = c.PostId
LEFT JOIN Votes v ON pd.PostId = v.PostId AND v.VoteTypeId = 8  -- Bounty votes
LEFT JOIN PostLinks pl ON pd.PostId = pl.PostId
LEFT JOIN Tags t ON t.Id = pl.RelatedPostId  -- Assuming PostLinks relate to Tags for representation
WHERE pd.Score > 10  -- Filtering for high-scoring posts
GROUP BY 
    pd.PostId, 
    pd.Title, 
    pd.CreationDate, 
    pd.Score, 
    pd.ViewCount, 
    pd.OwnerDisplayName,
    pd.OwnerUserId
HAVING COUNT(c.Id) > 5  -- Only include posts with more than 5 comments
ORDER BY pd.CreationDate DESC;
