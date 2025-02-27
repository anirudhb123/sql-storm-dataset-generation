WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.TotalViews,
        ua.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ua.TotalScore DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionCount > 10 -- Users with more than 10 questions
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalViews,
    tu.TotalScore,
    rp.Title,
    rp.CreationDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.UserRank <= 5 -- Only select top 5 users
ORDER BY 
    tu.TotalScore DESC, tu.DisplayName ASC;
