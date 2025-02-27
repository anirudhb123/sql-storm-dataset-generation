WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 50
    GROUP BY 
        U.Id
),
TopTags AS (
    SELECT 
        T.TagName, 
        COUNT(PT.PostId) AS TagUsageCount
    FROM 
        Tags T
    JOIN 
        Posts PT ON T.Id = ANY(string_to_array(PT.Tags, '><')::int[])
    GROUP BY 
        T.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 5
),
PostHistories AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleBodyTagEdits,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    US.DisplayName, 
    US.Reputation AS UserReputation, 
    US.PostCount, 
    US.QuestionCount, 
    US.AnswerCount, 
    US.PositiveScoreCount, 
    US.HighViewsCount, 
    TT.TagName, 
    PH.EditCount, 
    PH.TitleBodyTagEdits, 
    PH.LastEdited
FROM 
    UserStats US
JOIN 
    PostHistories PH ON US.UserId = PH.UserId
CROSS JOIN 
    TopTags TT
ORDER BY 
    US.Reputation DESC, 
    US.PostCount DESC, 
    PH.LastEdited DESC;
