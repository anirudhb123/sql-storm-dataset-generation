WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges
    FROM 
        UserStatistics
    WHERE 
        Rank <= 10
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.Score AS PostScore,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.TotalBadges,
    pi.Title AS PostTitle,
    pi.CreationDate AS PostCreationDate,
    pi.ViewCount,
    pi.CommentCount,
    pi.PostScore,
    pi.OwnerDisplayName AS PostOwner,
    pi.OwnerReputation AS PostOwnerReputation
FROM 
    TopUsers tu
LEFT JOIN 
    PostInfo pi ON tu.UserId = pi.OwnerUserId
ORDER BY 
    tu.TotalPosts DESC, pi.PostScore DESC;
