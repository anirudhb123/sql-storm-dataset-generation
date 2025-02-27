-- Performance Benchmarking Query
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount > 1000
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserDisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    pp.Title AS PopularPostTitle,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName
FROM 
    UserPostCounts up
LEFT JOIN 
    PopularPosts pp ON up.UserId = pp.OwnerDisplayName
JOIN 
    Users u ON u.Id = up.UserId
ORDER BY 
    up.PostCount DESC, up.QuestionCount DESC;
