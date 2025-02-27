WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.AnswerCount, P.ViewCount, P.Score
),
ClosedPostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.AnswerCount,
        PS.ViewCount,
        PS.Score,
        PH.CreationDate AS ClosedDate,
        PH.UserDisplayName AS ClosedBy
    FROM 
        PostStats PS
    JOIN 
        PostHistory PH ON PS.PostId = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 -- Filter for closed posts
),
UserPostInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpvotesReceived,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownvotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName AS User,
    UPS.PostsCreated,
    UPS.UpvotesReceived,
    UPS.DownvotesReceived,
    CPS.Title AS ClosedPostTitle,
    CPS.ClosedDate,
    CPS.ClosedBy,
    UVS.TotalVotes,
    UVS.Upvotes,
    UVS.Downvotes
FROM 
    UserPostInteractions UPS
LEFT JOIN 
    ClosedPostStats CPS ON UPS.UserId = CPS.ClosedBy
LEFT JOIN 
    UserVoteSummary UVS ON UPS.UserId = UVS.UserId
WHERE 
    (U.TotalVotes > 0 OR U.Upvotes > 0 OR U.Downvotes > 0)
ORDER BY 
    UPS.PostsCreated DESC, CPS.ClosedDate DESC
LIMIT 100;
