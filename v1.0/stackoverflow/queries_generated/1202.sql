WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')) AS t(TagName)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tr.UserId,
    u.DisplayName,
    u.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges
FROM 
    TopQuestions tq
LEFT JOIN 
    Posts p ON tq.PostId = p.Id
LEFT JOIN 
    Users tr ON tr.Id = p.OwnerUserId
LEFT JOIN 
    UserReputation ur ON tr.Id = ur.UserId
WHERE 
    ur.Reputation > 1000
ORDER BY 
    tq.Score DESC, tq.CreationDate ASC
LIMIT 50;

SELECT * FROM Posts 
WHERE 
    Score > 100
EXCEPT
SELECT * FROM Comments
WHERE 
    UserId IS NULL;
