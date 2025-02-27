WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           AVG(Reputation) OVER () AS AvgReputation
    FROM Users
), 
PostDetails AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, P.Score, P.ViewCount, 
           (SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.PostId = P.Id) AS TotalComments,
           (SELECT COUNT(*) 
            FROM Votes V 
            WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
           (SELECT COUNT(*) 
            FROM Votes V 
            WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(MONTH, -6, GETDATE())
), 
PostStatistics AS (
    SELECT PD.*, 
           CASE 
                WHEN PD.TotalComments IS NULL THEN 'No Comments' 
                ELSE CAST(PD.TotalComments AS VARCHAR) + ' Comments' 
           END AS CommentStatus,
           CASE 
                WHEN PD.UpVotes > PD.DownVotes THEN 'Positive Engagement'
                WHEN PD.UpVotes < PD.DownVotes THEN 'Negative Engagement'
                ELSE 'Neutral Engagement'
           END AS EngagementStatus
    FROM PostDetails PD
), 
HighestScoringPosts AS (
    SELECT TOP 5 PostId, Title, Score
    FROM PostStatistics
    ORDER BY Score DESC
),
VotesAggregation AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Votes
    GROUP BY PostId
),
PostsWithVoteStats AS (
    SELECT PS.*, 
           COALESCE(VA.UpVotesCount, 0) AS UpVotesCount,
           COALESCE(VA.DownVotesCount, 0) AS DownVotesCount
    FROM PostStatistics PS
    LEFT JOIN VotesAggregation VA ON PS.PostId = VA.PostId
)
SELECT U.DisplayName AS UserName, U.Reputation AS UserReputation, 
       P.Title AS PostTitle, P.CreationDate AS PostCreation, 
       P.Score AS PostScore, P.CommentStatus, 
       P.EngagementStatus, P.UpVotesCount, P.DownVotesCount
FROM Users U
JOIN UserReputation UR ON U.Id = UR.Id
LEFT JOIN PostsWithVoteStats P ON P.ViewCount > UR.AvgReputation
WHERE UR.Reputation > 1000
  AND P.PostCreation BETWEEN UR.CreationDate AND GETDATE()
ORDER BY P.Score DESC, P.PostCreation DESC
OPTION (MAXRECURSION 0);
