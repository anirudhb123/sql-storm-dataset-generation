WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
), 
TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT U.Id) AS UserCount
    FROM Tags T
    JOIN Posts P ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><'))::int)
    JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY T.TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UserCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagUsage
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalUps,
    UA.TotalDownVotes,
    UA.TotalVotes,
    UA.TotalPosts,
    UA.TotalComments,
    TT.TagName,
    TT.PostCount,
    TT.UserCount
FROM UserActivity UA
FULL OUTER JOIN TopTags TT ON UA.TotalVotes > 0 
WHERE UA.TotalPosts > 5 OR TT.TagRank <= 5
ORDER BY UA.TotalVotes DESC NULLS LAST, TT.PostCount DESC;
