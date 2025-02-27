
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.Reputation
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b 
    WHERE 
        b.Date >= NOW() - INTERVAL 2 YEAR
    GROUP BY 
        b.UserId, b.Name
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.PostCount,
        us.TotalBounties,
        rb.Name AS RecentBadge,
        rb.BadgeCount,
        rp.Title,
        rp.TagsArray
    FROM 
        UserStats us
    LEFT JOIN 
        RecentBadges rb ON us.UserId = rb.UserId
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
)

SELECT 
    f.UserId,
    f.Reputation,
    f.PostCount,
    f.TotalBounties,
    COALESCE(f.RecentBadge, 'None') AS RecentBadge,
    COALESCE(f.BadgeCount, 0) AS BadgeCount,
    f.Title,
    f.TagsArray
FROM 
    FinalStats f
ORDER BY 
    f.Reputation DESC, f.PostCount DESC;
