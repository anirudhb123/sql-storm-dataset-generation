WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(VoteValue), 0) AS TotalVotes,
        COALESCE(AVG(CASE WHEN C.UserId IS NOT NULL THEN C.Score ELSE NULL END), 0) AS AverageCommentScore,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            V.UserId,
            CASE 
                WHEN V.VoteTypeId = 2 THEN 1 
                WHEN V.VoteTypeId = 3 THEN -1 
                ELSE 0 
            END AS VoteValue
        FROM 
            Votes V
    ) AS VoteAggregates ON U.Id = VoteAggregates.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalVotes,
        AverageCommentScore,
        BadgeCount,
        TotalPosts,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserStatistics
), 
UserPerformance AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalVotes,
        AverageCommentScore,
        BadgeCount,
        TotalPosts,
        CASE 
            WHEN VoteRank <= 3 THEN 'Top Vote Earners'
            WHEN PostRank <= 3 THEN 'Top Post Creators'
            ELSE 'General User'
        END AS UserCategory
    FROM 
        TopUsers
)
SELECT 
    UP.DisplayName,
    UP.Reputation,
    UP.TotalVotes,
    UP.AverageCommentScore,
    UP.BadgeCount,
    UP.TotalPosts,
    UP.UserCategory,
    P.Title AS TopPostTitle,
    P.CreationDate AS TopPostCreationDate,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.UserId = UP.UserId) AS UserVotesOnPost
FROM 
    UserPerformance UP
LEFT JOIN 
    Posts P ON UP.UserId = P.OwnerUserId AND P.CreationDate = (
        SELECT MIN(CreationDate) 
        FROM Posts 
        WHERE OwnerUserId = UP.UserId
    )
WHERE 
    UP.UserCategory != 'General User'
ORDER BY 
    UP.TotalVotes DESC, 
    UP.TotalPosts DESC;
