WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBountyAllocated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBountyAllocated,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank,
        RANK() OVER (ORDER BY TotalBadges DESC) AS BadgeRank,
        RANK() OVER (ORDER BY TotalBountyAllocated DESC) AS BountyRank
    FROM 
        UserActivity
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBountyAllocated,
        PostRank,
        CommentRank,
        BadgeRank,
        BountyRank
    FROM 
        ActiveUsers
    WHERE 
        PostRank <= 10 OR CommentRank <= 10 OR BadgeRank <= 10 OR BountyRank <= 10
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalBadges,
    TotalBountyAllocated,
    LEAST(PostRank, CommentRank, BadgeRank, BountyRank) AS OverallRank
FROM 
    TopActiveUsers
ORDER BY 
    OverallRank;
