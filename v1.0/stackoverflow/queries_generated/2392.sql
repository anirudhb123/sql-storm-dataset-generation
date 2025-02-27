WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.Score) OVER (PARTITION BY U.Id) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserVoteStats
)

SELECT 
    T.DisplayName,
    T.TotalScore,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(PC.PostCount, 0) AS PostCount,
    CASE 
        WHEN T.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorType
FROM 
    TopUsers T
LEFT JOIN (
    SELECT 
        UserId, COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON T.UserId = B.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId, COUNT(Id) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
) PC ON T.UserId = PC.OwnerUserId
WHERE 
    T.PostCount > 5
ORDER BY 
    T.TotalScore DESC
LIMIT 20;
