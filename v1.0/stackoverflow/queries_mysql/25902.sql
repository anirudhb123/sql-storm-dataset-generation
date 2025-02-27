
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownVotes,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        TotalScore,
        @row_num := @row_num + 1 AS ScoreRank
    FROM UserActivity, (SELECT @row_num := 0) AS rn
    ORDER BY TotalScore DESC
),
ActiveTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostsWithTag,
        @tag_rank := @tag_rank + 1 AS TagRank
    FROM ActiveTags, (SELECT @tag_rank := 0) AS tr
    ORDER BY PostsWithTag DESC
)
SELECT 
    U.DisplayName AS ActiveUser,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalScore,
    T.TagName AS PopularTag,
    T.PostsWithTag
FROM TopUsers U
JOIN TopTags T ON U.ScoreRank = T.TagRank
WHERE U.ScoreRank <= 10 AND T.TagRank <= 10
ORDER BY U.TotalScore DESC, T.PostsWithTag DESC;
