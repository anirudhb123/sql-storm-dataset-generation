WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(b.Id) AS TotalBadges,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
), RankedUsers AS (
    SELECT 
        *,
        (UPPER(DisplayName) LIKE '%SQL%' OR UPPER(DisplayName) LIKE '%DATABASE%') AS IsSQLPro
    FROM 
        UserStats
), UserActivity AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        u.TotalBounty,
        u.TotalPosts,
        u.TotalQuestions,
        u.TotalAnswers,
        u.TotalBadges,
        u.UserRank,
        CASE 
            WHEN u.UserRank <= 10 THEN 'Top Contributor'
            ELSE 
                CASE 
                    WHEN u.TotalPosts > 100 THEN 'Active Contributor'
                    ELSE 'New Contributor'
                END
        END AS ContributorType
    FROM 
        RankedUsers u
), TopActiveUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalBounty,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalBadges,
    u.ContributorType,
    CASE 
        WHEN u.IsSQLPro THEN 'SQL Specialist'
        ELSE 'Generalist'
    END AS Specialty,
    COALESCE(SUM(ph.Comment), 'No Comments') AS LastEditRemarks,
    MAX(ph.CreationDate) AS LastActionDate
FROM 
    TopActiveUsers u
LEFT JOIN 
    PostHistory ph ON ph.UserId = u.UserId
WHERE 
    u.ActivityRank <= 20
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, u.TotalBounty, 
    u.TotalPosts, u.TotalQuestions, u.TotalAnswers, u.TotalBadges,
    u.ContributorType, u.IsSQLPro
ORDER BY 
    u.Reputation DESC, u.TotalPosts DESC;


