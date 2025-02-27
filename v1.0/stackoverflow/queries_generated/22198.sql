WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY U.Id
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0 
        END AS HasAcceptedAnswer,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS RankByViews
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Questions
      AND P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY T.Count DESC) AS TagRank
    FROM Posts P
    JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE P.PostTypeId = 1
)
SELECT 
    U.DisplayName,
    U.Reputation,
    RA.PostCount,
    RA.TotalUpvotes,
    RA.TotalDownvotes,
    QA.Title,
    QA.ViewCount AS MostViewed,
    QA.Score AS QuestionScore,
    QA.HasAcceptedAnswer,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM PostTags T 
     WHERE T.PostId = QA.PostId
     AND T.TagRank <= 3) AS TopTags,
    CASE 
        WHEN UT.UserId IS NOT NULL THEN 'Active User' 
        ELSE 'Inactive User' 
    END AS UserStatus
FROM RecentUserActivity RA
JOIN TopQuestions QA ON RA.PostCount > 10 AND RA.UserId = QA.PostId 
LEFT JOIN (
    SELECT DISTINCT 
        U.Id AS UserId 
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId 
    WHERE P.CreationDate < CURRENT_DATE - INTERVAL '1 year' 
) UT ON RA.UserId = UT.UserId
WHERE RA.ActivityRank <= 10
ORDER BY RA.Reputation DESC, QA.ViewCount DESC
LIMIT 5;
