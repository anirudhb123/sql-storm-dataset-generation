WITH TagCounts AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 -- Only for Questions
    GROUP BY Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount >= 5 -- Only consider tags used in 5 or more questions
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        SUM(COALESCE(CM.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(V.Score, 0)) AS TotalVoteScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.QuestionCount,
        UR.AnswerCount,
        UR.TotalCommentScore,
        UR.TotalVoteScore,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS Rank
    FROM UserReputation UR
    WHERE UR.QuestionCount > 0
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TT.Tag,
    TT.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalCommentScore,
    TU.TotalVoteScore
FROM TopUsers TU
JOIN TopTags TT ON TU.QuestionCount > 10 -- Users with more than 10 questions
ORDER BY TT.PostCount DESC, TU.Reputation DESC
LIMIT 10;
