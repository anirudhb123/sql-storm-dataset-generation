WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT PH.PostId) AS HistoryCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
Ranking AS (
    SELECT 
        TagName,
        PostCount,
        AnswerCount,
        QuestionCount,
        HistoryCount,
        ActiveUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank,
        RANK() OVER (ORDER BY HistoryCount DESC) AS HistoryRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    AnswerCount,
    QuestionCount,
    HistoryCount,
    ActiveUsers,
    PostRank,
    AnswerRank,
    HistoryRank
FROM 
    Ranking
WHERE 
    COALESCE(QuestionCount, 0) > 0
ORDER BY 
    PostCount DESC, AnswerCount DESC;
