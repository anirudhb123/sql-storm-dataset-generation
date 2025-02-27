WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
BadgeUser AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ba.GoldBadges,
    ba.SilverBadges,
    ba.BronzeBadges,
    tp.Title,
    tp.Score,
    tp.UpVotes,
    tp.DownVotes
FROM 
    Users u
INNER JOIN 
    BadgeUser ba ON u.Id = ba.UserId
LEFT JOIN 
    TopPosts tp ON u.Id = tp.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, tp.Score DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
