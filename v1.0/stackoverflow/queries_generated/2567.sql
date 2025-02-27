WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswerCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        COUNT(CR.PostId) AS CloseVoteCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments PC ON P.Id = PC.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN PostHistory CR ON P.Id = CR.PostId AND CR.Comment IS NOT NULL
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, PC.CommentCount
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.TotalBountyAmount,
    US.QuestionCount,
    US.AcceptedAnswerCount,
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.Score,
    PD.CreationDate,
    PD.CommentCount,
    PD.CloseVoteCount,
    PD.PostRank
FROM UserStats US
JOIN PostDetails PD ON US.UserId = PD.OwnerUserId
WHERE US.Reputation > 5000
ORDER BY US.Reputation DESC, PD.Score DESC
LIMIT 100;
