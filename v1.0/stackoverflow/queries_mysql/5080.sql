
WITH UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostsStats AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        COALESCE(PH.UserId, -1) AS LastEditedBy,
        PH.CreationDate AS LastEditDate
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
        SELECT MAX(Ph.CreationDate) 
        FROM PostHistory Ph
        WHERE Ph.PostId = P.Id
    )
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.Id) AS PostCount
    FROM Tags T
    JOIN Posts PT ON PT.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 5
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    P.Title AS LastPostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.AnswerCount,
    P.Score,
    T.TagName,
    T.PostCount
FROM UserStats U
LEFT JOIN PostsStats P ON U.Id = P.LastEditedBy
JOIN TopTags T ON T.TagName IN (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1)) AS TagName
    FROM 
        (SELECT @row := @row + 1 AS n 
        FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers,
        (SELECT @row := 0) init) numbers 
    WHERE n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) + 1
    )
    FROM Posts P
    WHERE P.Tags IS NOT NULL
)
WHERE U.Reputation > 100
ORDER BY U.Reputation DESC, P.CreationDate DESC;
