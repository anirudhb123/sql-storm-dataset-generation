
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
FlaggedUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        CASE 
            WHEN UR.Reputation < 100 THEN 'Low Reputation'
            WHEN UR.Reputation BETWEEN 100 AND 500 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationGroup
    FROM UserReputation UR
    WHERE UR.PostCount >= 10
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        @row_num := IF(@prev_user = P.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_user := P.OwnerUserId,
        COALESCE(PH.Comment, 'No comments') AS LastEditComment
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId 
    AND PH.PostHistoryTypeId IN (2, 4, 5)  
    JOIN (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE P.CreationDate > NOW() - INTERVAL 1 YEAR
    ORDER BY P.OwnerUserId, P.CreationDate DESC
),
PostsWithVoteCounts AS (
    SELECT 
        A.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN V.Id END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN V.Id END) AS DownVotes
    FROM ActivePosts A
    LEFT JOIN Votes V ON A.PostId = V.PostId
    GROUP BY A.PostId
)
SELECT 
    FU.ReputationGroup,
    AP.PostId,
    AP.Title,
    AP.ViewCount,
    PWC.UpVotes,
    PWC.DownVotes,
    COALESCE(UR.QuestionCount, 0) AS UserQuestionCount,
    COALESCE(UR.AnswerCount, 0) AS UserAnswerCount,
    CASE WHEN AP.PostRank = 1 THEN 'Latest Post' ELSE 'Earlier Post' END AS PostStatus
FROM ActivePosts AP
JOIN FlaggedUsers FU ON AP.PostId IN (
    SELECT P.Id FROM Posts P WHERE P.OwnerUserId = FU.UserId
)
LEFT JOIN PostsWithVoteCounts PWC ON AP.PostId = PWC.PostId
LEFT JOIN UserReputation UR ON FU.UserId = UR.UserId
WHERE AP.ViewCount IS NOT NULL
ORDER BY FU.ReputationGroup, AP.CreationDate DESC
LIMIT 50;
