
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
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
        TotalBounty,
        @row_number := IF(@prev_total_posts = TotalPosts AND @prev_total_bounty = TotalBounty, @row_number + 1, 1) AS rn,
        @prev_total_posts := TotalPosts,
        @prev_total_bounty := TotalBounty
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_total_posts := NULL, @prev_total_bounty := NULL) AS vars
    ORDER BY TotalPosts DESC, TotalBounty DESC
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBounty,
    CASE 
        WHEN tu.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty' 
    END AS BountyStatus,
    COALESCE(ti.Title, 'N/A') AS TopPostTitle,
    COUNT(DISTINCT cm.Id) AS TotalComments
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    Comments cm ON p.Id = cm.PostId
LEFT JOIN 
    (SELECT 
         p.Id, 
         p.Title, 
         @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS rn,
         @prev_owner_user_id := p.OwnerUserId
     FROM 
         Posts p, (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
     WHERE 
         p.PostTypeId = 1
     ORDER BY 
         p.OwnerUserId, p.CreationDate DESC
    ) ti ON p.Id = ti.Id AND ti.rn = 1
WHERE 
    tu.rn <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalQuestions, tu.TotalAnswers, tu.TotalBounty, ti.Title
ORDER BY 
    tu.TotalPosts DESC, tu.TotalBounty DESC;
