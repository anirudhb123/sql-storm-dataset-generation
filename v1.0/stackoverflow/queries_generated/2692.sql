WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.VoteTypeId = 2) OVER(PARTITION BY p.Id), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER(PARTITION BY p.Id), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    rb.BadgeCount,
    rb.LastBadgeDate
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
WHERE 
    (rp.UpvoteCount - rp.DownvoteCount) > 10
    AND rp.rn = 1
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
