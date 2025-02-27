
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId IN (1, 2)
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        AnswerCount,
        QuestionCount,
        BadgeCount,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        UserStats, (SELECT @userRank := 0) ur
    ORDER BY 
        AnswerCount DESC, QuestionCount DESC, BadgeCount DESC
)
SELECT 
    tt.Tag,
    tt.PostCount,
    ru.DisplayName AS TopUser,
    ru.AnswerCount,
    ru.QuestionCount,
    ru.BadgeCount
FROM 
    TopTags tt
INNER JOIN 
    RankedUsers ru ON ru.UserRank = 1
WHERE 
    tt.Rank <= 10  
ORDER BY 
    tt.PostCount DESC;
