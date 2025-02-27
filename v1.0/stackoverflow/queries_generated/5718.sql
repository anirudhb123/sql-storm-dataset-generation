WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserID,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), PostAggregates AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.OwnerReputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        ur.TotalBounties,
        COUNT(c.Id) AS CommentsCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostID
    JOIN 
        UserReputation ur ON ur.UserID = rp.OwnerUserId
    WHERE 
        rp.PostRank = 1
    GROUP BY 
        rp.PostID, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, ur.OwnerReputation, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges, ur.TotalBounties
)

SELECT 
    pa.PostID,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.OwnerReputation,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    pa.TotalBounties,
    pa.CommentsCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pa.PostID AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pa.PostID AND v.VoteTypeId = 3) AS Downvotes
FROM 
    PostAggregates pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC
LIMIT 10;
