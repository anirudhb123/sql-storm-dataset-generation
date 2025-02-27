WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPoster AS (
    SELECT 
        rp.OwnerUserId,
        us.DisplayName,
        COUNT(rp.Id) AS PostCount,
        SUM(rp.Score) AS TotalScore
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 3
    GROUP BY 
        rp.OwnerUserId, us.DisplayName
)
SELECT 
    tp.OwnerUserId,
    tp.DisplayName,
    tp.PostCount,
    tp.TotalScore,
    COALESCE(u.Reputation, 0) AS Reputation,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges
FROM 
    TopPoster tp
LEFT JOIN 
    UserStatistics u ON tp.OwnerUserId = u.UserId
LEFT JOIN 
    (SELECT 
         UserId,
         SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
         SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
         SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
     FROM 
         Badges 
     GROUP BY 
         UserId) b ON tp.OwnerUserId = b.UserId
WHERE 
    tp.TotalScore > 50
ORDER BY 
    tp.TotalScore DESC, tp.PostCount DESC;
