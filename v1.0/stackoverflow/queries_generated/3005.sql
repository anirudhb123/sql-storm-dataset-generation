WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        up.PostId,
        up.Title,
        up.Score,
        up.CommentCount,
        ur.Reputation,
        ur.TotalBadges,
        COALESCE(UP.ScoreRank, 0) AS UserRank
    FROM 
        RankedPosts up
    JOIN 
        UserReputation ur ON up.OwnerUserId = ur.UserId
)
SELECT 
    PostId,
    Title,
    Score,
    CommentCount,
    Reputation,
    TotalBadges,
    CASE 
        WHEN Reputation > 1000 THEN 'High Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    FinalResults
WHERE 
    Score > 5 
    OR UserRank <= 5
ORDER BY 
    Reputation DESC, 
    Score DESC;
