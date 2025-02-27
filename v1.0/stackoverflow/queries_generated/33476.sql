WITH RecursiveBadgeCounts AS (
    -- Recursive CTE to count badges per user and flag for high reputation users
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    GROUP BY 
        b.UserId
),
HighReputationUsers AS (
    SELECT 
        UserId,
        BadgeCount 
    FROM 
        RecursiveBadgeCounts 
    WHERE 
        MaxReputation > 1000
),
PostStats AS (
    -- CTE for calculating post statistics
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CloseReasons AS (
    -- CTE to gather closing reasons for posts
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = cr.Id::text
    WHERE 
        ph.PostHistoryTypeId = 10 -- Filtering only close events
    GROUP BY 
        ph.PostId
),
UserPostStats AS (
    -- Combining user and post statistics
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageViewCount, 0) AS AverageViewCount,
        COALESCE(cr.CloseReasonNames, 'No Close Reasons') AS CloseReasonNames
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        CloseReasons cr ON cr.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    WHERE 
        u.Reputation > 100 -- Only users with reputation above 100
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        u.TotalPosts,
        u.TotalScore,
        u.AverageViewCount,
        b.BadgeCount
    FROM 
        UserPostStats u
    JOIN 
        HighReputationUsers b ON u.UserId = b.UserId
)

SELECT 
    DisplayName,
    TotalPosts,
    TotalScore,
    AverageViewCount,
    BadgeCount
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, 
    TotalPosts DESC
LIMIT 50;  -- Limiting to top 50 based on TotalScore
This SQL query is structured to benchmark performance while retrieving user and post metrics from multiple related tables. It utilizes CTEs for structured data processing, includes outer joins to fetch missing data, and employs aggregated functions to calculate statistics based on complex queries that represent a realistic scenario querying StackOverflow-like schema.
