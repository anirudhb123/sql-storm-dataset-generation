WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.Tags,
        P.OwnerUserId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts AP WHERE AP.ParentId = P.Id) AS AnswerCount
    FROM Posts P
    WHERE P.PostTypeId = 1
),
VotesSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.Tags,
    U.DisplayName AS OwnerName,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    PD.CommentCount,
    PD.AnswerCount,
    U.Reputation AS OwnerReputation,
    U.UserRank,
    CASE 
        WHEN PD.Score > 0 THEN 'Positive'
        WHEN PD.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM PostDetails PD
LEFT JOIN TopUsers U ON PD.OwnerUserId = U.UserId
LEFT JOIN VotesSummary VS ON PD.PostId = VS.PostId
WHERE (PD.CommentCount > 10 OR PD.Score > 5)
  AND U.Reputation > 1000
ORDER BY PD.CreationDate DESC
LIMIT 100;

WITH RECURSIVE AnswerChain AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        AC.Level + 1
    FROM Posts P
    JOIN AnswerChain AC ON P.ParentId = AC.Id
)
SELECT 
    AC.Id AS AnswerPostId,
    AC.Title,
    AC.Level
FROM AnswerChain AC
WHERE AC.Level <= 2
ORDER BY AC.Level, AC.Title;
