WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    AND 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty start and close
    GROUP BY 
        u.Id, u.DisplayName
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalBounties,
        us.AvgViews,
        ub.BadgeNames,
        ROW_NUMBER() OVER (ORDER BY us.QuestionCount DESC, us.TotalBounties DESC) AS Rank
    FROM 
        UserStats us
    LEFT JOIN 
        UserBadges ub ON us.UserId = ub.UserId
    WHERE 
        us.QuestionCount > 0
)

SELECT 
    u.DisplayName,
    u.QuestionCount,
    u.TotalBounties,
    u.AvgViews,
    u.BadgeNames,
    rp.Title AS LatestPost,
    rp.CreationDate AS LatestPostDate
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    u.Rank <= 10
ORDER BY 
    u.QuestionCount DESC, 
    u.TotalBounties DESC;

This query achieves the following:
- It aggregates data about users who posted questions over the last year, calculating their statistics regarding questions posted, bounties received, and average views on their posts.
- It incorporates badge information for users and ranks them based on the number of questions and total bounties.
- It retrieves the title and creation date of the latest question posted by the top-ranked users.
- It uses CTEs (Common Table Expressions), window functions, and left joins to structure the data efficiently.
