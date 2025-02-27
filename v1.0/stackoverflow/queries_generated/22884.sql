WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT BA.Id) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges BA ON U.Id = BA.UserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.LastActivityDate,
        P.Title,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RecentRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.LastActivityDate IS NOT NULL
),
AggregatedStats AS (
    SELECT 
        U.UserId,
        S.Reputation,
        S.TotalUpVotes,
        S.TotalDownVotes,
        S.TotalPosts,
        S.TotalBadges,
        COALESCE(AVG(RP.ViewCount), 0) AS AvgViewCount,
        STRING_AGG(RP.Title, ', ') AS RecentTitles
    FROM 
        UserStatistics S
    LEFT JOIN 
        RecentPosts RP ON S.UserId = RP.OwnerDisplayName AND RP.RecentRank <= 5
    GROUP BY 
        S.UserId, S.Reputation, S.TotalUpVotes, S.TotalDownVotes, S.TotalPosts, S.TotalBadges
)

SELECT 
    A.UserId,
    A.Reputation,
    A.TotalUpVotes,
    A.TotalDownVotes,
    A.TotalPosts,
    A.TotalBadges,
    A.AvgViewCount,
    A.RecentTitles,
    CASE 
        WHEN A.TotalPosts > 0 THEN 
            CONCAT('User rank: ', CAST(A.Reputation AS VARCHAR(10)), ' - Posts: ', CAST(A.TotalPosts AS VARCHAR(10)), ' - Titles: ', COALESCE(A.RecentTitles, 'No recent posts'))
        ELSE 
            'No posts available'
    END AS UserSummary
FROM 
    AggregatedStats A
WHERE 
    A.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (A.TotalUpVotes - A.TotalDownVotes) > 5 
ORDER BY 
    A.Reputation DESC, A.TotalPosts DESC;
