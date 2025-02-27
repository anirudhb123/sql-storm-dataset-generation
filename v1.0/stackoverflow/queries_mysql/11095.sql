
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
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
        NegativeScorePosts,
        @rank := @rank + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rank := 0) r
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
    NegativeScorePosts
FROM 
    TopUsers
WHERE 
    Rank <= 10;
