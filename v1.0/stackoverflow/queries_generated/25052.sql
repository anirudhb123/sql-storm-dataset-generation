WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        COUNT(DISTINCT A.Id) AS TotalAnswers,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN C.Score IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Questions
    LEFT JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2 -- Answers
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 5
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerUser,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownvoteCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > now() - interval '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName
)
SELECT 
    UEng.UserId,
    UEng.DisplayName,
    UEng.Reputation,
    UEng.TotalQuestions,
    UEng.TotalAnswers,
    UEng.TotalUpvotes,
    UEng.TotalDownvotes,
    UEng.TotalComments,
    PT.TagName AS PopularTag,
    PS.PostId,
    PS.Title AS RecentPostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.OwnerUser AS PostOwner,
    PS.CommentCount,
    PS.UpvoteCount,
    PS.DownvoteCount
FROM UserEngagement UEng
CROSS JOIN PopularTags PT
LEFT JOIN PostStatistics PS ON UEng.UserId = PS.OwnerUser
ORDER BY UEng.Reputation DESC, PT.PostCount DESC;
