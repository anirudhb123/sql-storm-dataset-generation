WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ViewCount,
        P.Score,
        COALESCE(H.Comment, 'No Paradox') AS HistoryComment,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory H ON H.PostId = P.Id AND H.PostHistoryTypeId IN (10, 11)
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
UserPostStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        COUNT(DISTINCT PD.PostId) FILTER (WHERE PD.PostRank = 1) AS RecentPosts,
        AVG(PD.ViewCount) AS AvgViewCount,
        SUM(PD.Score) AS TotalScore,
        STRING_AGG(DISTINCT PD.HistoryComment, ', ') AS HistoryComments
    FROM 
        UserActivity UA
    LEFT JOIN 
        PostDetails PD ON UA.UserId = PD.OwnerUserId
    GROUP BY 
        UA.UserId
),
FilteredUsers AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        U.Reputation 
    FROM 
        UserPostStats U
    WHERE 
        U.Reputation > 100 AND 
        (U.RecentPosts > 5 OR U.TotalScore > 20)
),
CombinedMetrics AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        FilteredUsers U
    LEFT JOIN 
        Votes V ON V.UserId = U.UserId AND V.VoteTypeId = 8
    GROUP BY 
        U.UserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.Reputation,
    C.TotalBounties,
    COALESCE(U.PostCount, 0) AS UserPostCount,
    COALESCE(U.CommentCount, 0) AS UserCommentCount
FROM 
    CombinedMetrics C
FULL OUTER JOIN 
    UserActivity U ON C.UserId = U.UserId
WHERE 
    (C.TotalBounties > 0 OR U.PostCount > 0)
ORDER BY 
    C.Reputation DESC, 
    U.Views DESC;

This SQL query does the following:
1. **Common Table Expressions (CTEs)**: Uses multiple CTEs to break down the query into manageable segments. This includes user activity, post details associated with the users, and filtering for users meeting certain activity thresholds.
2. **Aggregations**: Uses various aggregations like `SUM`, `COUNT`, and `AVG` to calculate metrics based on user interactions.
3. **Window Functions**: Implements `ROW_NUMBER` to rank posts of each user based on creation date.
4. **Conditional Logic**: Filter functionality utilizing conditional aggregates and NULL handling.
5. **Combined Data**: Finally combines user metrics from CTEs into a comprehensive selection utilizing a `FULL OUTER JOIN` to ensure all relevant users and their activity data are included, including edge cases where users may exist without posts or bounties.
6. **Comment Strings**: Aggregation of post history comments into a string for insights on user interaction over time.

This query is elaborate enough to test various aspects of SQL performance, including join strategies, aggregation efficiency, and overall complexity management.
