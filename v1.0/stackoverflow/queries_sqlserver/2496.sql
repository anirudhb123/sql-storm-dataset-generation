
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty
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
        *,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS Rank
    FROM 
        UserMetrics
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)  
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
