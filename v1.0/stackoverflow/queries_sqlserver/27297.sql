
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        ISNULL(SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END), 0) AS QuestionScore,
        ISNULL(SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END), 0) AS AnswerScore,
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
        value AS Tag
    FROM 
        STRING_SPLIT(Tags, '><')
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
    ORDER BY 
        COUNT(*) DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
