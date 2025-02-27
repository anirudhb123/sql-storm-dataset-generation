WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
ActiveTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, '><')::int[])
    GROUP BY 
        T.TagName
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UA.DisplayName AS User,
    UA.QuestionCount,
    UA.UpVoteCount,
    UA.DownVoteCount,
    UA.AvgPostScore,
    UA.CommentCount,
    AT.TagName,
    AT.PostCount,
    AT.AcceptedAnswers,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.CloseCount,
    PHS.ReopenCount
FROM 
    UserActivity UA
JOIN 
    ActiveTags AT ON UA.QuestionCount > 0
JOIN 
    PostHistoryStats PHS ON UA.UserId = PHS.UserId
ORDER BY 
    UA.QuestionCount DESC,
    UA.UpVoteCount DESC,
    AT.PostCount DESC
LIMIT 50;
