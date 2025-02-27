
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a) n
    WHERE 
        PostTypeId = 1 
        AND CHAR_LENGTH(Tags) > 2
        AND n.n <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1) 
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
    WHERE 
        PostCount > 10 
    ORDER BY 
        PostCount DESC
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        @rank2 := @rank2 + 1 AS Rank
    FROM 
        UserReputation, (SELECT @rank2 := 0) r
    WHERE 
        QuestionCount > 5 
)

SELECT 
    T.Tag,
    T.PostCount AS TotalQuestions,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.QuestionCount AS UserQuestionCount,
    U.AnswerCount AS UserAnswerCount,
    U.BadgeCount AS UserBadgeCount
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.QuestionCount = (
        SELECT 
            MAX(QuestionCount) 
        FROM 
            TopUsers 
        WHERE 
            EXISTS (
                SELECT 1 
                FROM Posts P 
                WHERE 
                    P.OwnerUserId = U.UserId 
                    AND FIND_IN_SET(T.Tag, SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1)) > 0
            )
    )
ORDER BY 
    T.PostCount DESC, U.Reputation DESC
LIMIT 10;
