WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
TopUsers AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.Reputation,
        Us.PostCount,
        Us.TotalBounties,
        Us.UpVotes,
        Us.DownVotes
    FROM UserStats Us
    WHERE Us.Reputation > 1000 AND Us.PostCount > 5
    ORDER BY Us.Reputation DESC
    LIMIT 5
)
SELECT 
    Tu.DisplayName AS TopUserDisplayName,
    Tu.Reputation AS TopUserReputation,
    Tu.PostCount AS TopUserPostCount,
    Tu.TotalBounties AS TopUserTotalBounties,
    Tu.UpVotes AS TopUserUpVotes,
    Tu.DownVotes AS TopUserDownVotes,
    Tg.TagName AS PopularTag
FROM TopUsers Tu
CROSS JOIN TopTags Tg
ORDER BY Tu.Reputation DESC, Tg.PostCount DESC;
