WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(JSON_AGG(DISTINCT T.TagName) FILTER (WHERE T.TagName IS NOT NULL), '[]') AS Tags
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(P.Tags, '><')) AS TagName
    ) T ON TRUE
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS Score,
        Tags
    FROM UserScores
    WHERE PostCount > 5
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Score,
        Tags,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS Rank
    FROM TopUsers
    WHERE Score > 0
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Score,
    R.Rank,
    CASE 
        WHEN R.Rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM RankedUsers R
LEFT JOIN Badges B ON R.UserId = B.UserId
WHERE B.Class = 1 OR B.Class = 2
ORDER BY R.Rank;
