WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBountyEarned
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
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        TotalComments,
        Questions,
        Answers,
        TotalBadges,
        TotalBountyEarned,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank,
        RANK() OVER (ORDER BY TotalBountyEarned DESC) AS BountyRank
    FROM 
        UserStats
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.Questions,
    tu.Answers,
    tu.TotalBadges,
    tu.TotalBountyEarned,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
WHERE 
    tu.PostRank <= 10 OR tu.CommentRank <= 10 OR tu.BountyRank <= 10
ORDER BY 
    tu.TotalPosts DESC, tu.TotalComments DESC;
