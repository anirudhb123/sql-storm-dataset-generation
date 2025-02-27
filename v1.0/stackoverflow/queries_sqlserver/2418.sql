
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
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
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    AND PH.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        PS.TotalPosts,
        PS.TotalScore,
        RANK() OVER (ORDER BY US.Reputation DESC) AS UserRank
    FROM UserScore US
    JOIN PostStats PS ON US.UserId = PS.OwnerUserId
    WHERE US.Reputation > 1000
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalPosts,
    TU.TotalScore,
    COUNT(RE.EditRank) AS RecentEditCount,
    STRING_AGG(RE.Comment, '; ') AS EditComments
FROM TopUsers TU
LEFT JOIN RecentEdits RE ON TU.UserId = RE.UserId
GROUP BY TU.DisplayName, TU.TotalPosts, TU.TotalScore
HAVING COUNT(RE.EditRank) > 0
ORDER BY TU.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
