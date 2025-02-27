
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH 
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
),
DetailedPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        P.CreationDate,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        ClosedPosts CP ON P.Id = CP.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    DP.Title,
    DP.Score,
    DP.CloseCount,
    DP.CreationDate,
    CASE 
        WHEN DP.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopUsers TU
JOIN 
    DetailedPostStats DP ON TU.UserId = DP.PostId
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, DP.Score DESC;
