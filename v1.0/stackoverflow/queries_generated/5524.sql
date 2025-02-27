WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        AVG(U.Reputation) AS AverageReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS TagUsage
    FROM Tags T
    JOIN Posts PT ON T.Id = PT.Id /* Assuming the Tags are aligned with Posts in some manner */
    GROUP BY T.TagName
    ORDER BY TagUsage DESC
    LIMIT 10
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate
)
SELECT 
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalBounty,
    US.AverageReputation,
    PT.TagName,
    PT.TagUsage,
    PA.Title AS PostTitle,
    PA.CommentCount,
    PA.VoteCount,
    PA.LastEditDate
FROM UserStats US
CROSS JOIN PopularTags PT
JOIN PostActivity PA ON PA.PostId = (
    SELECT Id 
    FROM Posts 
    WHERE OwnerUserId = US.UserId 
    ORDER BY CreationDate DESC 
    LIMIT 1
) 
ORDER BY US.TotalPosts DESC, PT.TagUsage DESC, PA.VoteCount DESC
LIMIT 100;
