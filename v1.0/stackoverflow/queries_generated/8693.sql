WITH UserScoreRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TopPosts AS (
    SELECT 
        PS.*,
        R.ReputationRank
    FROM 
        PostStatistics PS
    JOIN UserScoreRankings R ON PS.PostId IN (
        SELECT 
            A.AcceptedAnswerId 
        FROM 
            Posts A 
        WHERE 
            A.OwnerUserId = R.UserId
    )
    ORDER BY 
        PS.Score DESC
    LIMIT 100
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    TP.AcceptedAnswers,
    US.DisplayName AS UserName,
    US.Reputation AS UserReputation,
    US.ReputationRank
FROM 
    TopPosts TP
JOIN Users US ON TP.UserId = US.Id
ORDER BY 
    TP.Score DESC, 
    US.Reputation DESC;
