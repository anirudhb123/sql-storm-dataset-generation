
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        AVG(p.Score) AS AvgPostScore,
        AVG(p.ViewCount) AS AvgViewCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT TRIM(BOTH '<>' FROM tag) AS tag FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
        FROM (SELECT a.N + b.N * 10 + 1 AS n
              FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
              CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
              ) numbers
        WHERE 
            numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag_list
        ) AS tag
    ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUserPostStats AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AcceptedAnswerCount,
        AvgPostScore,
        AvgViewCount,
        Tags,
        @rownum := @rownum + 1 AS PostRank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    AvgPostScore,
    AvgViewCount,
    Tags
FROM 
    TopUserPostStats
WHERE 
    PostRank <= 10
ORDER BY 
    AvgPostScore DESC;
