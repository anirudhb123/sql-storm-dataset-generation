WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalOutput AS (
    SELECT 
        up.UserId,
        up.DisplayName, 
        ur.Reputation, 
        ur.GoldBadges, 
        ur.SilverBadges, 
        ur.BronzeBadges, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.PostRank
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.UserId = rp.OwnerUserId
    JOIN 
        Users up ON rp.OwnerUserId = up.Id
)
SELECT 
    *,
    CASE 
        WHEN Reputation >= 1000 THEN 'Veteran'
        WHEN Reputation >= 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    FinalOutput
WHERE 
    PostRank = 1
ORDER BY 
    Reputation DESC, 
    Score DESC;
