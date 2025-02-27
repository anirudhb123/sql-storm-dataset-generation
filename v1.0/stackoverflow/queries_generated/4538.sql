WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(CAST((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS INTEGER), 0) AS CommentCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
AnswerStats AS (
    SELECT 
        PD.PostId,
        SUM(CASE WHEN P.AcceptedAnswerId = PD.PostId THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM PostDetails PD
    LEFT JOIN Posts P ON PD.AcceptedAnswerId = P.Id
    LEFT JOIN Votes V ON V.PostId = PD.PostId
    GROUP BY PD.PostId
),
FinalResults AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        AS.AnnouncedAnswerCount,
        AS.TotalUpvotes,
        AS.TotalDownvotes,
        (AS.TotalUpvotes - AS.TotalDownvotes) AS NetScore
    FROM UserReputation UR
    JOIN PostDetails PD ON PD.OwnerUserId = UR.UserId
    JOIN AnswerStats AS ON PD.PostId = AS.PostId
    WHERE UR.ReputationRank <= 10
)
SELECT 
    FR.DisplayName,
    FR.Title,
    FR.CreationDate,
    FR.Score,
    FR.AcceptedAnswersCount,
    FR.TotalUpvotes,
    FR.TotalDownvotes,
    FR.NetScore,
    CASE 
        WHEN FR.NetScore > 0 THEN 'Positive'
        WHEN FR.NetScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM FinalResults FR
ORDER BY FR.NetScore DESC
LIMIT 50;
