WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        us.DisplayName,
        us.PostCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        ROW_NUMBER() OVER(ORDER BY rp.Score DESC, rp.ViewCount DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.DisplayName,
    tp.PostCount,
    CASE 
        WHEN tp.GoldBadges > 0 THEN 'Gold' 
        WHEN tp.SilverBadges > 0 THEN 'Silver' 
        WHEN tp.BronzeBadges > 0 THEN 'Bronze' 
        ELSE 'No Badges' 
    END AS BadgeLevel,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
         FROM PostHistory ph 
         JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
         WHERE ph.PostId = tp.PostId AND ph.Comment IS NOT NULL 
         GROUP BY ph.PostId), 
    'No Comments') AS HistoricalComments
FROM 
    TopPosts tp
WHERE 
    tp.ScoreRank <= 10
ORDER BY 
    tp.Score DESC, tp.PostId ASC;
