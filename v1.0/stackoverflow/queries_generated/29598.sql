WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
), 
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Reputation, 0)) AS TotalReputation,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageScore,
    ua.DisplayName AS TopUser,
    ua.TotalPosts,
    ua.TotalScore,
    ua.LastPostDate
FROM 
    TagStats ts
JOIN 
    UserActivity ua ON ua.TotalPosts = (
        SELECT MAX(TotalPosts) 
        FROM UserActivity u
        WHERE u.TotalPosts > 0
    )
ORDER BY 
    ts.AverageScore DESC, 
    ts.PostCount DESC
LIMIT 10;
