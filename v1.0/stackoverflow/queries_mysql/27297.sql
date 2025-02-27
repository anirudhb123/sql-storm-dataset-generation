
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END), 0) AS QuestionScore,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END), 0) AS AnswerScore,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        COUNT(*) DESC
    LIMIT 10
),
PopularUsers AS (
    SELECT 
        UR.DisplayName,
        UR.QuestionScore,
        UR.AnswerScore,
        UR.TotalPosts,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        UserReputation UR
    LEFT JOIN 
        Badges B ON UR.UserId = B.UserId
    WHERE 
        UR.TotalPosts > 5
    GROUP BY 
        UR.UserId, UR.DisplayName, UR.QuestionScore, UR.AnswerScore, UR.TotalPosts
    ORDER BY 
        UR.QuestionScore + UR.AnswerScore DESC
    LIMIT 5
)
SELECT 
    PU.DisplayName,
    PU.QuestionScore,
    PU.AnswerScore,
    PU.BadgeCount,
    TT.Tag
FROM 
    PopularUsers PU
CROSS JOIN 
    TopTags TT
ORDER BY 
    PU.QuestionScore + PU.AnswerScore DESC, PU.BadgeCount DESC;
