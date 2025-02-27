
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AvgUserReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgUserReputation,
        @row_num := @row_num + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @row_num := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.AvgUserReputation,
    (SELECT 
        GROUP_CONCAT(CONCAT(U.DisplayName, ' (', U.Reputation, ')') ORDER BY U.Reputation DESC SEPARATOR ', ') 
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LIMIT 5) AS TopContributors
FROM 
    TopTags T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.PostCount DESC;
