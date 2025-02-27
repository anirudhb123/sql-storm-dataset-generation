
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
        Posts P ON P.Tags LIKE '%' + '<' + T.TagName + '>'
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
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.AvgUserReputation,
    (SELECT 
        STRING_AGG(U.DisplayName + ' (' + CAST(U.Reputation AS VARCHAR) + ')', ', ') 
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Tags LIKE '%' + '<' + T.TagName + '>'
    FETCH FIRST 5 ROWS ONLY) AS TopContributors
FROM 
    TopTags T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.PostCount DESC;
