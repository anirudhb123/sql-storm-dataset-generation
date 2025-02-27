
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount,
        COUNT(DISTINCT OwnerUserId) AS UniqueUserCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
         CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1 >= n.n
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UniqueUserCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.TagName,
    t.PostCount,
    t.UniqueUserCount,
    u.UserId,
    u.DisplayName AS MostActiveUser,
    u.QuestionsAsked,
    u.UpvotedQuestions,
    u.TotalViews
FROM 
    TopTags t
JOIN 
    UserStats u ON u.QuestionsAsked = (
        SELECT MAX(QuestionsAsked)
        FROM UserStats
        WHERE QuestionsAsked > 0
    )
WHERE 
    t.Rank <= 5 
ORDER BY 
    t.Rank,
    u.TotalViews DESC;
