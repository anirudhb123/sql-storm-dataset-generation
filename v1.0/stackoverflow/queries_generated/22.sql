WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS Rank
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
        u.Id
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalComments, 
        TotalBadges, 
        TotalBounty, 
        TotalScore,
        Rank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0 AND 
        TotalComments > 10 AND 
        Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBadges,
    tu.TotalBounty,
    CASE WHEN tu.Rank <= 5 THEN 'Top Contributor' ELSE 'Active User' END AS UserType,
    STRING_AGG(t.TagName, ', ') AS TagsUsed
FROM 
    TopUsers tu
LEFT JOIN 
    (SELECT unnest(string_to_array(Tags, '<>')) AS TagName, OwnerUserId FROM Posts WHERE Tags IS NOT NULL) t ON tu.UserId = t.OwnerUserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.TotalPosts, tu.TotalComments, tu.TotalBadges, tu.TotalBounty, tu.Rank
ORDER BY 
    tu.TotalScore DESC, tu.Reputation DESC;
