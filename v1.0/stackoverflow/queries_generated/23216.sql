WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswers,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
CloseReasonCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount,
        SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS CommentedClosedPosts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalViews,
        ups.TotalScore,
        ups.AvgAnswers,
        COALESCE(crc.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(crc.CommentedClosedPosts, 0) AS CommentedClosedPosts,
        CASE 
            WHEN ups.ViewRank <= 10 THEN 'Top User'
            ELSE 'Regular User'
        END AS UserType
    FROM 
        UserPostStats ups
    LEFT JOIN 
        CloseReasonCounts crc ON ups.UserId = crc.UserId
),
InactiveUserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS InactivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate < NOW() - INTERVAL '1 year' 
    WHERE 
        u.LastAccessDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.PostCount,
    cs.TotalViews,
    cs.TotalScore,
    cs.AvgAnswers,
    cs.ClosedPostCount,
    cs.CommentedClosedPosts,
    COALESCE(iup.InactivePostCount, 0) AS InactivePostCount
FROM 
    CombinedStats cs
LEFT JOIN 
    InactiveUserPostCount iup ON cs.UserId = iup.UserId
WHERE 
    cs.TotalScore > 10 OR cs.ClosedPostCount > 0
ORDER BY 
    cs.TotalScore DESC, cs.PostCount DESC;

This query includes the following complex constructs:

1. **Common Table Expressions (CTEs)**: Multiple CTEs for organizing the data into meaningful chunks.
2. **Join Operations**: Utilizes `LEFT JOIN` to ensure no users are lost even if they haven't created any posts or closed any.
3. **Aggregations**: Summation, count, and average operations to assess user post statistics and total scores.
4. **Window Functions**: Using `RANK()` to rank users based on total views.
5. **NULL Logic**: Implementing `COALESCE` and conditional expressions to handle NULL values.
6. **Complicated Predicates**: The `WHERE` clause uses multiple conditions to filter results.
7. **String Expressions**: The case statement provides a user type based on their rank.
8. **Temporal Filtering**: Conditions are included for filtering posts created over a year ago to identify inactive users.

This SQL query is designed to benchmark performance with complex processing of user and post-related statistics from the provided schema while addressing multiple SQL granularities and edge cases.
