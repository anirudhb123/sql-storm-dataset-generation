WITH RECURSIVE UserBadges AS (
    -- Get all users and their badges with class counts
    SELECT 
        U.Id AS UserId,
        U.DisplayName, 
        B.Class, 
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, B.Class
),

RankedUsers AS (
    -- Create a ranking of users based on their badge count for each class
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        RANK() OVER (PARTITION BY Class ORDER BY BadgeCount DESC) AS BadgeRank
    FROM UserBadges
),

PostStatistics AS (
    -- Calculate statistics on posts that received votes
    SELECT 
        P.Id AS PostId, 
        P.Title,
        COUNT(V.Id) AS TotalVotes,
        AVG(V.BountyAmount) AS AverageBountyAmount,
        SUM(COALESCE(V.BountyAmount, 0)) as TotalBounty,
        MAX(P.CreationDate) as LatestPostDate
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
),

CombinedStats AS (
    -- Joining ranked user statistics with post statistics
    SELECT 
        RU.DisplayName,
        RU.BadgeCount,
        PS.PostId,
        PS.Title,
        PS.TotalVotes,
        PS.TotalBounty,
        PS.LatestPostDate
    FROM RankedUsers RU
    JOIN PostStatistics PS ON RU.BadgeRank = 1 -- Only top users with their best class
)

-- Final result set combining information
SELECT 
    CS.DisplayName,
    CS.BadgeCount,
    CS.PostId,
    CS.Title,
    CS.TotalVotes,
    CS.TotalBounty,
    CASE 
        WHEN CS.LatestPostDate >= NOW() - INTERVAL '1 month' THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivityStatus
FROM CombinedStats CS
ORDER BY CS.BadgeCount DESC, CS.TotalVotes DESC
LIMIT 10;
