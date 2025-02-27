WITH RecursivePostCount AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ParentId,
        P.Score,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ParentId,
        P.Score,
        RPC.Level + 1
    FROM Posts P
    INNER JOIN RecursivePostCount RPC ON P.ParentId = RPC.PostId
),
QuestionMetrics AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT Q.Id) AS QuestionCount,
        SUM(COALESCE(Q.Score, 0)) AS TotalScore,
        COUNT(CASE WHEN Q.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers
    FROM RecursivePostCount Q
    JOIN Users U ON Q.OwnerUserId = U.Id
    GROUP BY U.DisplayName
),
TagsWithCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN Q.PostTypeId = 1 THEN 1 END) AS QuestionsAsked,
        COUNT(CASE WHEN A.PostTypeId = 2 THEN 1 END) AS AnswersGiven,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyEarned
    FROM Users U
    LEFT JOIN Posts Q ON U.Id = Q.OwnerUserId AND Q.PostTypeId = 1
    LEFT JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UA.DisplayName,
    UA.QuestionsAsked,
    UA.AnswersGiven,
    UA.TotalBountyEarned,
    QM.QuestionCount,
    QM.TotalScore,
    QM.AcceptedAnswers,
    TW.TagName,
    TW.PostCount
FROM UserActivity UA
LEFT JOIN QuestionMetrics QM ON UA.DisplayName = QM.DisplayName
LEFT JOIN TagsWithCounts TW ON TW.PostCount > 5
ORDER BY UA.TotalBountyEarned DESC, QM.TotalScore DESC;
