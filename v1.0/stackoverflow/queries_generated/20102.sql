WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
        CASE 
            WHEN Reputation >= 10000 THEN 'High Repute'
            WHEN Reputation >= 1000 THEN 'Medium Repute'
            ELSE 'Low Repute'
        END AS ReputationCategory
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(p.ClosedDate, '1970-01-01'::timestamp) AS ClosureDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        ARRAY_LENGTH(string_to_array(p.Tags, ','), 1) AS TagCount,
        EXTRACT(YEAR FROM p.CreationDate) AS CreationYear
    FROM Posts p
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM PostHistory
    WHERE PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tags modified
    GROUP BY PostId
),
ActiveUsers AS (
    SELECT
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(COALESCE(ph.EditCount, 0)) AS TotalEdits,
        AVG(COALESCE(uv.Rank, 0)) AS AvgPostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistoryCounts ph ON p.Id = ph.PostId
    LEFT JOIN UserReputation uv ON u.Id = uv.UserId
    WHERE u.LastAccessDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        DisplayName,
        ActivePostCount,
        TotalEdits,
        AvgPostRank,
        ROW_NUMBER() OVER (ORDER BY ActivePostCount DESC, TotalEdits DESC) AS UserRank
    FROM ActiveUsers
)
SELECT 
    tu.DisplayName,
    tu.ActivePostCount,
    tu.TotalEdits,
    CASE 
        WHEN tu.AvgPostRank IS NULL THEN 'Unknown'
        WHEN tu.AvgPostRank < 1 THEN 'No Posts'
        ELSE 'Active Contributor'
    END AS ContributorStatus,
    pd.Title,
    pd.TagCount,
    CASE 
        WHEN pd.UserPostRank = 1 THEN 'Latest'
        ELSE 'Earlier Post'
    END AS PostStatus,
    COALESCE(pts.Name, 'No Type') AS PostType
FROM TopUsers tu
LEFT JOIN PostDetails pd ON tu.ActivePostCount = pd.OwnerUserId
LEFT JOIN PostTypes pts ON pd.PostId = pts.Id
WHERE tu.UserRank <= 10
ORDER BY tu.ActivePostCount DESC, tu.TotalEdits DESC;

### Explanation of Query Constructs:
- **CTEs**: Multiple Common Table Expressions (UserReputation, PostDetails, PostHistoryCounts, ActiveUsers, TopUsers) are used to break the query down into manageable logical parts.
- **Window Functions**: Functions like `ROW_NUMBER()` and `DENSE_RANK()` are utilized to determine ranks for users and posts.
- **Correlated Subqueries**: Use within CTEs to pull aggregated data from related tables, like counting post edits.
- **String and NULL Logic**: Handling tags and potential NULL values appropriately, employing COALESCE and string functions.
- **Case Statements**: Implementing business logic to categorize data into understandable labels.
- **Outer Joins**: Utilized to ensure that even users without posts or edit history are still included in the results.
- **Complex predicates**: Various filtering and grouping conditions showcase complexity, ensuring nuanced results.
