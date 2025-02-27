WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        B.Name AS BadgeName, 
        B.Class,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
),
UserVoteCounts AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM Votes V
    GROUP BY V.UserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ISNULL(UB.UpVotesCount, 0) AS UpVotesCount,
        ISNULL(UB.DownVotesCount, 0) AS DownVotesCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserVoteCounts UB ON U.Id = UB.UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 -- Only questions
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId, 
        P.Title,
        PH.CreationDate AS HistoryDate,
        PHT.Name AS PostHistoryType,
        COUNT(*) OVER (PARTITION BY PH.PostId) AS EditCount
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PHT.Id IN (4, 5, 6) -- Title, body, and tags edited
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(BadgeName, 'No Badge') AS LatestBadge,
    UserRank,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.AnswerCount,
    PD.CommentCount,
    PD.ViewCount,
    COALESCE(PHD.EditCount, 0) AS TotalEdits,
    STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
FROM TopUsers U
LEFT JOIN PostDetails PD ON U.Id = PD.OwnerUserId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId AND UB.BadgeRank = 1
LEFT JOIN PostHistoryDetails PHD ON PD.PostId = PHD.PostId
LEFT JOIN PostHistoryTypes PHT ON PHT.Id = PHD.PostHistoryTypeId
WHERE U.UserRank <= 50 -- Top 50 users by reputation
GROUP BY U.Id, U.DisplayName, U.Reputation, UserRank, PD.PostId, PD.Title, PD.CreationDate, PD.Score, 
         PD.AnswerCount, PD.CommentCount, PD.ViewCount
ORDER BY U.Reputation DESC, PD.CreationDate DESC;
