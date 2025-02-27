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
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, or Tags
    AND PH.CreationDate > current_timestamp - INTERVAL '30 days'
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
    STRING_AGG(DISTINCT RE.Comment, '; ') AS EditComments
FROM TopUsers TU
LEFT JOIN RecentEdits RE ON TU.UserId = RE.UserId
GROUP BY TU.DisplayName, TU.TotalPosts, TU.TotalScore
HAVING COUNT(RE.EditRank) > 0
ORDER BY TU.TotalScore DESC
LIMIT 10;
