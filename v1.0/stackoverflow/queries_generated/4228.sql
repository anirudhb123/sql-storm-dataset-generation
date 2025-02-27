WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, U.DisplayName
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UserRank,
        CASE 
            WHEN rp.UserRank = 1 THEN 'Top Post'
            WHEN rp.CommentCount > 5 THEN 'Popular Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        Case 
            WHEN Reputation IS NULL THEN 'Unranked'
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation < 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM 
        Users 
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.PostCategory,
    ur.Reputation,
    ur.ReputationCategory
FROM 
    PostStats ps
JOIN 
    UserReputation ur ON ps.OwnerDisplayName = ur.Id
WHERE 
    ps.Score > (SELECT AVG(Score) FROM Posts) 
    OR 
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) > 10
ORDER BY 
    ps.Score DESC;
