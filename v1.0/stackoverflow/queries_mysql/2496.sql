
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalBounty,
        @rank := @rank + 1 AS Rank
    FROM 
        UserMetrics, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC, TotalScore DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        @recent_rank := IF(@prev_user = p.OwnerUserId, @recent_rank + 1, 1) AS RecentPostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @recent_rank := 0, @prev_user := NULL) r
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR) 
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    ru.Reputation,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalScore,
    ru.TotalBounty,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM 
    RankedUsers ru
LEFT JOIN 
    RecentPosts rp ON ru.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
WHERE 
    ru.TotalPosts > 10 
ORDER BY 
    ru.Rank
LIMIT 10;
