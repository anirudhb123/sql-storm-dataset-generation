WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Only bounties
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalBounties,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalComments,
        us.TotalBadges,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY us.TotalBounties DESC) AS BountyRank
    FROM 
        UserStats us
),

RankedBadges AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalComments,
    tu.TotalBounties,
    rb.BadgeNames,
    CASE 
        WHEN tu.PostRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor' 
    END AS ContributorLevel
FROM 
    TopUsers tu
    LEFT JOIN RankedBadges rb ON tu.UserId = rb.UserId
WHERE 
    tu.TotalPosts > 0
    AND tu.TotalBounties > 0
ORDER BY 
    tu.TotalPosts DESC, tu.TotalBounties DESC;
