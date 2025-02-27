WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted,
        SUM(COALESCE(CN.CommentCount, 0)) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS UpVotesReceived,
        SUM(V.VoteTypeId = 3) AS DownVotesReceived,
        AVG(UP.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) CN ON CN.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastModified,
        PH.UserDisplayName AS LastEditor,
        P.Title,
        P.Body,
        P.LastEditDate,
        PH.Comment AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY 
        PH.PostId, PH.UserDisplayName, P.Title, P.Body, P.LastEditDate, PH.Comment
),
TagUserInteractions AS (
    SELECT 
        T.TagName,
        UA.UserId,
        UA.DisplayName,
        COUNT(P.Id) AS PostsUnderTag,
        SUM(UA.UpVotesReceived) AS TotalUpVotes,
        SUM(UA.DownVotesReceived) AS TotalDownVotes
    FROM 
        TagStatistics T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        UserActivity UA ON UA.UserId = P.OwnerUserId
    GROUP BY 
        T.TagName, UA.UserId, UA.DisplayName
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.HighViewCountPosts,
    UA.DisplayName AS ActiveUser,
    UA.TotalPosts,
    UA.QuestionsPosted,
    UA.AnswersPosted,
    UA.TotalComments,
    UA.UpVotesReceived,
    UA.DownVotesReceived,
    PHA.LastModified,
    PHA.LastEditor,
    PHA.CloseReason
FROM 
    TagStatistics T
LEFT JOIN 
    UserActivity UA ON UA.QuestionCount > 0
LEFT JOIN 
    PostHistoryAnalysis PHA ON PHA.PostId = (SELECT MAX(PostId) FROM PostHistory WHERE PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || T.TagName || '%'))
ORDER BY 
    T.TagName, UA.DisplayName;
