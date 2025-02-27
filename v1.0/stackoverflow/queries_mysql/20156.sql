
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE
        U.Reputation >= 100 AND
        U.CreationDate < NOW() - INTERVAL 1 YEAR
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        UpVotes, 
        DownVotes, 
        GoldBadges,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS UserRank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT
        Tags.TagName,
        COUNT(P.Id) AS PopularPostCount
    FROM 
        Posts P
    JOIN 
        Tags ON P.Tags LIKE CONCAT('%', Tags.TagName, '%')
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(P.Id) > 5
    ORDER BY 
        PopularPostCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.PostCount AS TotalPosts,
    TU.UpVotes AS TotalUpVotes,
    TU.DownVotes AS TotalDownVotes,
    TU.GoldBadges,
    PT.TagName AS PopularTag,
    COALESCE(PT.PopularPostCount, 0) AS PopularPostCount
FROM 
    TopUsers TU
LEFT JOIN 
    PopularTags PT ON TU.UpVotes > (SELECT AVG(UpVotes) FROM TopUsers)
ORDER BY 
    TU.UserRank
LIMIT 10 OFFSET 5;
