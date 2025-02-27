WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),

PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT AH.Id) AS AnswerCount,
        SUM(COALESCE(B.Reputation, 0)) AS TotalReputationOnAnswers
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Posts AH ON P.Id = AH.ParentId AND AH.PostTypeId = 2
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY P.Id
),

ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        P.Title AS ClosedPostTitle
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10
),

RankedPosts AS (
    SELECT 
        PS.*,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.Score DESC) AS Rank
    FROM PostSummary PS
    WHERE PS.Score IS NOT NULL
),

UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)

SELECT 
    U.DisplayName AS UserName,
    PS.Title AS PostTitle,
    PS.Score AS PostScore,
    PS.CommentCount,
    PS.AnswerCount,
    COALESCE(CLOSED.ClosedPostTitle, 'Not Closed') AS ClosedPostTitle,
    UVS.TotalVotes,
    UVS.Upvotes,
    UVS.Downvotes,
    UBC.BadgeCount,
    CASE 
        WHEN PS.Score IS NULL THEN 'No Score'
        WHEN PS.Score > 100 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreEvaluation
FROM UserVoteSummary UVS
JOIN Posts P ON UVS.UserId = P.OwnerUserId
JOIN RankedPosts PS ON P.Id = PS.PostId
LEFT JOIN ClosedPostHistory CLOSED ON PS.PostId = CLOSED.PostId
JOIN UserBadgeCounts UBC ON UVS.UserId = UBC.UserId
WHERE PS.Rank = 1
ORDER BY PS.Score DESC, UVS.TotalVotes DESC
LIMIT 50;
