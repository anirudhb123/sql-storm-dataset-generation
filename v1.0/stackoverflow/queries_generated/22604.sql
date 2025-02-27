WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        COALESCE(A.Score, 0) AS AcceptScore,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId
),

ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT C.Name) AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        PH.PostId
)

SELECT 
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.BadgeCount,
    PD.Title,
    PD.CreationDate,
    PD.AcceptScore,
    PD.CommentCount,
    COALESCE(CPH.CloseCount, 0) AS CloseCount,
    COALESCE(CPH.CloseReasons, '{}') AS CloseReasons,
    (PD.UpVotes - PD.DownVotes) AS NetVotes,
    CASE 
        WHEN PD.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS EngagementStatus
FROM 
    UserStatistics US
JOIN 
    PostDetails PD ON US.UserId = PD.OwnerUserId
LEFT JOIN 
    ClosedPostHistory CPH ON PD.PostId = CPH.PostId
WHERE 
    US.Reputation > 1000
    AND COALESCE(CPH.CloseCount, 0) < 3
ORDER BY 
    NetVotes DESC,
    PD.CreationDate DESC
LIMIT 50;

This SQL query does the following:
1. **CTEs for User Statistics**: It calculates various statistics for users, such as the number of posts, questions, answers, and badges.
2. **CTEs for Post Details**: It gathers details about posts created in the last year, including their titles, creation dates, accepted answer scores, comment counts, and upvote/downvote counts.
3. **CTE for Closed Post History**: It counts how many times each post was closed, aggregating the reasons for closure.
4. The final selection pulls together this data, calculating net votes, engagement status, and filtering based on reputation and closure counts.
5. The output is ordered primarily by net votes and then by creation date, limited to 50 results for performance benchmarking.

