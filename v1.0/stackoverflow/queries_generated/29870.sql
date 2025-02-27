WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        AVG(COALESCE(V.VoteCount, 0)) AS AverageVotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags ILIKE '%' || T.TagName || '%'
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        TotalComments,
        AverageVotes,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalAnswers,
    T.TotalComments,
    T.AverageVotes
FROM 
    TopTags T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.PostCount DESC;

WITH ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseReasonCount,
        ARRAY_AGG(DISTINCT CRT.Name) AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
    GROUP BY 
        PH.PostId
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    CPR.CloseReasonCount,
    CPR.CloseReasons
FROM 
    Posts P
LEFT JOIN 
    ClosedPostReasons CPR ON P.Id = CPR.PostId
WHERE 
    P.PostTypeId = 1 -- Only questions
ORDER BY 
    CPR.CloseReasonCount DESC NULLS LAST;

WITH UserReputationBoost AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation + COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1000 WHEN B.Class = 2 THEN 500 WHEN B.Class = 3 THEN 100 END), 0) AS TotalReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalReputation
FROM 
    UserReputationBoost U
WHERE 
    U.TotalReputation > 3000
ORDER BY 
    U.TotalReputation DESC
LIMIT 5;
