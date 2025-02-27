WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01'
),
PostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= '2023-01-01'
    GROUP BY 
        b.UserId
)
SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AvgViewCount,
    COALESCE(rb.BadgeCount, 0) AS TotalBadges,
    COALESCE(rb.BadgeNames, 'No Badges') AS BadgeNames
FROM 
    PostSummary ps
LEFT JOIN 
    RecentBadges rb ON ps.UserId = rb.UserId
WHERE 
    ps.TotalPosts > 0
ORDER BY 
    ps.TotalScore DESC, ps.TotalPosts DESC
LIMIT 10;

WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
    UNION ALL
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount + p.AnswerCount,
        ups.TotalBounty + COALESCE(v.BountyAmount, 0)
    FROM 
        UserPostStats ups
    JOIN 
        Posts p ON ups.UserId = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 2
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalBounty
FROM 
    UserPostStats ups
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalBounty DESC
LIMIT 5;
