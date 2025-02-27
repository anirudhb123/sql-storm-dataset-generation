WITH RecursiveUserActivity AS (
    -- CTE to calculate user activity over time inclusive of accepted answers and votes
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT P.AcceptedAnswerId) AS AcceptedAnswers,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RowNum
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentBadgeCount AS (
    -- CTE to count badges per user, denoting recent achievements
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date > CURRENT_DATE - INTERVAL '1 year' -- Only count badges earned in the last year
    GROUP BY 
        B.UserId
),
UserMetrics AS (
    -- Aggregate user metrics including badges and post activity
    SELECT
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.AcceptedAnswers,
        UA.TotalVotes,
        UA.UpVotes,
        UA.DownVotes,
        COALESCE(RBC.BadgeCount, 0) AS RecentBadges
    FROM 
        RecursiveUserActivity UA
    LEFT JOIN 
        RecentBadgeCount RBC ON UA.UserId = RBC.UserId
    WHERE 
        UA.RowNum = 1 -- Select the latest user activity data
)
SELECT
    UM.DisplayName,
    UM.TotalPosts,
    UM.AcceptedAnswers,
    UM.TotalVotes,
    UM.UpVotes,
    UM.DownVotes,
    UM.RecentBadges,
    CASE 
        WHEN UM.TotalVotes > 50 THEN 'Highly Active'
        WHEN UM.TotalVotes > 20 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    COALESCE(PT.Name, 'Unknown') AS PostType
FROM 
    UserMetrics UM
LEFT JOIN 
    Posts P ON UM.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    UM.TotalPosts > 0 -- Filter users who have at least one post
ORDER BY 
    UM.UpVotes DESC,
    UM.RecentBadges DESC
LIMIT 10; -- Returning the top 10 active users
