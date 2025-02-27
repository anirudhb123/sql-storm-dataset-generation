
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        @rank := @rank + 1 AS Rank
    FROM Users U, (SELECT @rank := 0) r
    ORDER BY U.Reputation DESC
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentEdits AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        @edit_rank := IF(@current_post = PH.PostId, @edit_rank + 1, 1) AS EditRank,
        @current_post := PH.PostId
    FROM PostHistory PH, (SELECT @edit_rank := 0, @current_post := NULL) r
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    AND PH.CreationDate > '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY PH.PostId, PH.CreationDate DESC
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        PS.TotalPosts,
        PS.TotalScore,
        @user_rank := @user_rank + 1 AS UserRank
    FROM UserScore US, (SELECT @user_rank := 0) r
    JOIN PostStats PS ON US.UserId = PS.OwnerUserId
    WHERE US.Reputation > 1000
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalPosts,
    TU.TotalScore,
    COUNT(RE.EditRank) AS RecentEditCount,
    GROUP_CONCAT(DISTINCT RE.Comment SEPARATOR '; ') AS EditComments
FROM TopUsers TU
LEFT JOIN RecentEdits RE ON TU.UserId = RE.UserId
GROUP BY TU.DisplayName, TU.TotalPosts, TU.TotalScore
HAVING COUNT(RE.EditRank) > 0
ORDER BY TU.TotalScore DESC
LIMIT 10;
