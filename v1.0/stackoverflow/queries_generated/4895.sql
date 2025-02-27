WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        u.Reputation AS OwnerReputation,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.CreationDate,
        rp.OwnerReputation,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.PostRank = 1 AND rp.OwnerReputation > 1000
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.ViewCount,
        fp.CreationDate,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId IN (2, 3)) 
            THEN 'HasVotes' 
            ELSE 'NoVotes' 
        END AS VoteStatus,
        COALESCE((SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = fp.PostId), 0) AS RelatedLinks
    FROM FilteredPosts fp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CreationDate,
    pd.VoteStatus,
    pd.RelatedLinks,
    STRING_AGG(distinct pt.Name, ', ') AS PostTypeNames,
    COUNT(DISTINCT b.Name) AS BadgeCount,
    MAX(b.Class) AS HighestBadgeClass
FROM PostDetails pd
LEFT JOIN PostTypes pt ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN Badges b ON b.UserId IN (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = pd.PostId)
GROUP BY pd.PostId, pd.Title, pd.Score, pd.ViewCount, pd.CreationDate, pd.VoteStatus, pd.RelatedLinks
HAVING COUNT(DISTINCT b.Name) > 0
ORDER BY pd.Score DESC, pd.ViewCount DESC;
