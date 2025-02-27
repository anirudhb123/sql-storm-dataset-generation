WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Last year
),
PostStats AS (
    SELECT 
        r.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        AVG(r.Score) AS AvgScore,
        SUM(r.ViewCount) AS TotalViews
    FROM 
        RankedPosts r
    GROUP BY 
        r.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        ps.TotalQuestions,
        ps.AvgScore,
        ps.TotalViews,
        RANK() OVER (ORDER BY ps.TotalQuestions DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 1000 -- Only considering users with reputation greater than 1000
),
MostActiveUsers AS (
    SELECT 
        u.DisplayName, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    WHERE 
        c.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- Last 6 months
    GROUP BY 
        u.DisplayName
), 
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.AvgScore,
    tu.TotalViews,
    CASE 
        WHEN mab.CommentCount IS NOT NULL THEN mab.CommentCount
        ELSE 0 
    END AS RecentCommentCount,
    ub.BadgeNames
FROM 
    TopUsers tu
LEFT JOIN 
    MostActiveUsers mab ON tu.DisplayName = mab.DisplayName
LEFT JOIN 
    UserBadges ub ON tu.OwnerUserId = ub.UserId
WHERE 
    tu.UserRank <= 10 -- Top 10 users by questions asked
ORDER BY 
    tu.TotalQuestions DESC;
