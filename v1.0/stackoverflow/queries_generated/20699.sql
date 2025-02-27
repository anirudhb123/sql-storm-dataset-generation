WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId IN (1, 2)) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpvoteCount,
        DownvoteCount,
        PostCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > now() - INTERVAL '30 days'
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        AVG(LENGTH(C.Text)) AS AvgCommentLength
    FROM Comments C
    GROUP BY C.PostId
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerName,
        PC.CommentCount,
        PC.AvgCommentLength,
        UP.Reputation AS OwnerReputation
    FROM RecentPosts RP
    LEFT JOIN PostComments PC ON RP.PostId = PC.PostId
    JOIN Users U ON RP.OwnerName = U.DisplayName
    JOIN TopUsers UP ON U.Id = UP.UserId
    WHERE UP.UserRank <= 10
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.OwnerName,
    FP.CommentCount,
    FP.AvgCommentLength,
    FP.OwnerReputation,
    CASE 
        WHEN FP.CommentCount IS NULL THEN 'No comments'
        WHEN FP.CommentCount < 5 THEN 'Few comments'
        ELSE 'Active discussion'
    END AS CommentEngagement,
    CONCAT(FP.OwnerName, ' has posted ', FP.AvgCommentLength, ' characters on average in comments.') AS CommentMessage,
    (SELECT COALESCE(MAX(Score), 0) 
     FROM Votes V WHERE V.PostId = FP.PostId AND V.VoteTypeId = 2) AS MaxUpvote
FROM FilteredPosts FP
ORDER BY FP.OwnerReputation DESC NULLS LAST, FP.CommentCount DESC;
