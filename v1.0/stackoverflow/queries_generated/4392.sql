WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AcceptedAnswerId,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVoteCount,
        (SELECT U.DisplayName FROM Users U WHERE U.Id = P.OwnerUserId) AS OwnerDisplayName
    FROM Posts P
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        T.Name AS PostHistoryType,
        PH.Comment
    FROM PostHistory PH
    INNER JOIN PostHistoryTypes T ON PH.PostHistoryTypeId = T.Id
    WHERE T.Name IN ('Post Closed', 'Post Reopened')
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (PARTITION BY PD.OwnerDisplayName ORDER BY PD.ViewCount DESC) AS RankByViews
    FROM PostDetails PD
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalScore,
    COALESCE(RP.Title, 'No Posts') AS TopPostTitle,
    COALESCE(RP.ViewCount, 0) AS TopPostViewCount,
    COALESCE(CPH.PostHistoryType, 'No History') AS HistoryType,
    CPH.CreationDate AS HistoryDate,
    U.BadgeCount
FROM UserStatistics U
LEFT JOIN RankedPosts RP ON U.UserId = RP.OwnerDisplayName
LEFT JOIN ClosedPostHistory CPH ON RP.Id = CPH.PostId AND CPH.CreationDate = (SELECT MAX(CreationDate) FROM ClosedPostHistory WHERE PostId = RP.Id)
WHERE U.Reputation > 100 AND U.PostCount > 5
ORDER BY U.Reputation DESC, U.PostCount DESC;
