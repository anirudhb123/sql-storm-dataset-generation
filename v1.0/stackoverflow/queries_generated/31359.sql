WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Assuming starting from Questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.CreationDate,
        P2.PostTypeId,
        P2.AcceptedAnswerId,
        Level + 1
    FROM Posts P2
    INNER JOIN RecursivePostHierarchy PH ON PH.PostId = P2.ParentId
)
, UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 4 THEN 1 END) AS OffensiveVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScoreRanking AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
    WHERE P.Score IS NOT NULL
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, '; ') AS Comments
    FROM Comments C
    GROUP BY C.PostId
)

SELECT 
    PH.PostId,
    PH.Title,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    PH.CreationDate,
    PS.Score AS PostScore,
    PS.ScoreRank,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    PC.Comments,
    US.UpVotes,
    US.DownVotes,
    US.OffensiveVotes,
    PH.Level AS PostLevel
FROM RecursivePostHierarchy PH
JOIN Users U ON PH.OwnerUserId = U.Id
LEFT JOIN PostScoreRanking PS ON PH.PostId = PS.Id
LEFT JOIN PostComments PC ON PH.PostId = PC.PostId
LEFT JOIN UserVoteStats US ON U.Id = US.UserId
WHERE PH.Level <= 3  -- Limit to 3 levels deep
ORDER BY PH.Level, PS.Score DESC;
