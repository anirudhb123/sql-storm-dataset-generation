
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgViewCount,
        AvgScore,
        @rownum := @rownum + 1 AS TotalPostsRank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.AvgViewCount,
    tu.AvgScore,
    ub.BadgeCount,
    ub.BadgeList
FROM 
    TopUsers tu
JOIN 
    (SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeList
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id) ub ON tu.UserId = ub.UserId
WHERE 
    tu.TotalPostsRank <= 10
ORDER BY 
    tu.TotalPosts DESC;
