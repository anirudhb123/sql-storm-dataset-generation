WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Questions from the last year
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.DisplayName AS OwnerDisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per user
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Fetch top 10 posts overall
