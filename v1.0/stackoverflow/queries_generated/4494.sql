WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalBadges,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount
    FROM 
        UserWithBadges u
    JOIN 
        RankedPosts p ON u.UserId = p.OwnerUserId
    WHERE 
        p.PostRank = 1 AND u.TotalBadges > 0
)

SELECT 
    t.DisplayName,
    t.Title,
    COALESCE(p.Score, 0) AS PostScore,
    COALESCE(p.AnswerCount, 0) AS AnswerCount,
    COALESCE(p.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN b.Class IS NOT NULL THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    TopUsers t
LEFT JOIN 
    Badges b ON t.UserId = b.UserId
WHERE 
    (t.TotalBadges > 0 AND b.Id IS NOT NULL) OR b.Id IS NULL
ORDER BY 
    t.DisplayName, PostScore DESC
LIMIT 100;

