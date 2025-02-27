WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        TotalPosts,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY DownVotes ASC) AS DownvoteRank
    FROM UserVotes
),
ActiveTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    INNER JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    WHERE T.Count > 5
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.TotalPosts,
    A.TagName,
    A.PostCount,
    (U.UpVotes - U.DownVotes) AS NetVotes
FROM TopUsers U
JOIN ActiveTags A ON U.TotalPosts > 10
WHERE U.UpvoteRank <= 5 OR U.DownvoteRank <= 5
ORDER BY NetVotes DESC, U.DisplayName;
