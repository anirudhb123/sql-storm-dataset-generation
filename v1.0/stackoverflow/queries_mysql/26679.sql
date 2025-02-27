
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPostCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews
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
        PostCount,
        QuestionCount,
        AnswerCount,
        UpvotedPostCount,
        TotalViews,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        TotalViews DESC
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UpvotedPostCount,
    u.TotalViews,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') 
     FROM Posts p 
     JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
     WHERE p.OwnerUserId = u.UserId) AS PopularTags
FROM 
    TopUsers u
WHERE 
    Rank <= 10
ORDER BY 
    u.TotalViews DESC;
