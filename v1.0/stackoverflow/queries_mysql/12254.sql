
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        U.CreationDate,
        (U.UpVotes - U.DownVotes) AS VoteScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.UpVotes, U.DownVotes, U.Views, U.CreationDate
)

SELECT 
    Us.UserId,
    Us.Reputation,
    Us.VoteScore,
    Us.PostCount,
    Us.CommentCount,
    Us.QuestionCount,
    Us.AnswerCount,
    Us.BadgeCount,
    @reputationRank := IF(@prevReputation = Us.Reputation, @reputationRank, @rankId := @rankId + 1) AS ReputationRank,
    @prevReputation := Us.Reputation,
    @voteScoreRank := IF(@prevVoteScore = Us.VoteScore, @voteScoreRank, @voteScoreId := @voteScoreId + 1) AS VoteScoreRank,
    @prevVoteScore := Us.VoteScore,
    @postCountRank := IF(@prevPostCount = Us.PostCount, @postCountRank, @postCountId := @postCountId + 1) AS PostCountRank,
    @prevPostCount := Us.PostCount
FROM 
    UserScores Us,
    (SELECT @rankId := 0, @prevReputation := NULL, @reputationRank := 0, 
            @voteScoreId := 0, @prevVoteScore := NULL, @voteScoreRank := 0, 
            @postCountId := 0, @prevPostCount := NULL, @postCountRank := 0) r
ORDER BY 
    Us.Reputation DESC, Us.VoteScore DESC
LIMIT 100;
