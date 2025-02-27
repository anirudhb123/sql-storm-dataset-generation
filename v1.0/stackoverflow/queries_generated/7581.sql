WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT r.Id) AS PostCount,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalScore,
    us.TotalViews,
    us.TotalAnswers,
    us.TotalComments,
    CASE 
        WHEN us.PostCount > 10 THEN 'Active Contributor'
        WHEN us.TotalScore > 1000 THEN 'Highly Respected'
        ELSE 'New Contributor'
    END AS UserCategory
FROM 
    UserStats us
WHERE 
    us.TotalViews > 1000
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC;
