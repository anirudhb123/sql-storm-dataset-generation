WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE()) -- within the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
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
ActivitySummary AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        UserWithBadges u
    LEFT JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- filtering only bounty related votes
    GROUP BY 
        u.UserId, u.DisplayName
)
SELECT 
    u.DisplayName,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    a.TotalViews,
    a.TotalAnswers,
    a.TotalBounties,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.CommentCount AS RecentPostComments,
    rp.CreationDate AS RecentPostDate
FROM 
    UserWithBadges u
FULL OUTER JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.PostRank = 1 -- getting the most recent post
LEFT JOIN 
    ActivitySummary a ON u.UserId = a.UserId
WHERE 
    (u.BadgeCount > 0 OR a.TotalViews > 1000) -- filtering users with either badges or high view counts
ORDER BY 
    u.BadgeCount DESC, a.TotalViews DESC;
