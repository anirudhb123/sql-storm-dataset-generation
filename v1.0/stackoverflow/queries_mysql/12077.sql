
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.ViewCount) AS AverageViewCount
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
        Questions, 
        Answers, 
        PositiveScorePosts, 
        AverageViewCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    PositiveScorePosts,
    AverageViewCount
FROM 
    TopUsers
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
