WITH TagCounts AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.TagName) AS TagCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN substring_array((
        SELECT string_agg(Tags, ',')
        FROM UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS Tags
    ), ',') AS T ON T.Tags IS NOT NULL
    GROUP BY U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT
        UserId,
        DisplayName,
        TagCount
    FROM TagCounts
    WHERE TagCount >= 5
),
UserScore AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(U.UpVotes) - SUM(U.DownVotes) AS VoteNet,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
BenchmarkResults AS (
    SELECT
        PU.UserId,
        PU.DisplayName,
        US.TotalBounty,
        US.VoteNet,
        US.TotalPosts,
        US.LastPostDate
    FROM PopularUsers PU
    JOIN UserScore US ON PU.UserId = US.UserId
)
SELECT
    BR.DisplayName,
    BR.TotalBounty,
    BR.VoteNet,
    BR.TotalPosts,
    BR.LastPostDate,
    CASE
        WHEN BR.TotalBounty > 100 THEN 'High'
        WHEN BR.TotalBounty BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS BountyLevel,
    CASE
        WHEN BR.TotalPosts > 50 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM BenchmarkResults BR
ORDER BY BR.TotalPosts DESC, BR.TotalBounty DESC;
