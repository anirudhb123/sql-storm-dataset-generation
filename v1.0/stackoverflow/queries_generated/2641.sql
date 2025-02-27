WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.CommentCount,
    ua.VoteCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
WHERE 
    rp.rn = 1 AND 
    (ua.CommentCount > 50 OR ua.VoteCount > 100)
ORDER BY 
    ua.DisplayName ASC, rp.ViewCount DESC
LIMIT 10;

SELECT 
    1 AS DummyColumn
WHERE 
    NOT EXISTS (SELECT 1 FROM Posts WHERE Score < 0)
UNION
SELECT 
    2 AS DummyColumn
WHERE 
    EXISTS (SELECT 1 FROM Votes WHERE CreationDate >= CURRENT_DATE - INTERVAL '30 days' AND VoteTypeId = 2);
