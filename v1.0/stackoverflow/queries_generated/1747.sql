WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        LastAccessDate,
        CASE 
            WHEN Reputation IS NULL THEN 'No Reputation'
            WHEN Reputation < 100 THEN 'Low Reputation'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM Users
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
), 
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CommentCount,
        ps.AverageBounty,
        ur.ReputationCategory
    FROM PostStatistics ps
    JOIN UserReputation ur ON ps.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
    WHERE ps.CommentCount > 5 AND ps.Score > 0
)
SELECT 
    fp.*,
    CASE 
        WHEN fp.AverageBounty IS NULL THEN 'No Bounty'
        ELSE CONCAT('Bounty: $', fp.AverageBounty)
    END AS BountyInfo
FROM FilteredPosts fp
ORDER BY fp.Score DESC, fp.CommentCount DESC
LIMIT 10
UNION ALL
SELECT 
    0 AS PostId,
    'Total Posts with Bounty and Comments' AS Title,
    CURRENT_TIMESTAMP AS CreationDate,
    COUNT(*) AS Score,
    SUM(CommentCount) AS CommentCount,
    AVG(AverageBounty) AS AverageBounty,
    NULL AS ReputationCategory,
    CASE 
        WHEN AVG(AverageBounty) IS NULL THEN 'No Bounty'
        ELSE CONCAT('Bounty: $', ROUND(AVG(AverageBounty), 2))
    END AS BountyInfo
FROM FilteredPosts;
