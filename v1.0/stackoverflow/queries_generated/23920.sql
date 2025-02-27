WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS AcceptedQuestions,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING(t.TagName FROM 1 FOR 20))) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    WHERE 
        p.Title IS NOT NULL 
        AND t.Count > 50
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS HistoryComments,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate IS NOT NULL
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.Reputation,
    IFNULL(pt.PostCount, 0) AS PopularTagCount,
    us.BadgeCount,
    us.AcceptedQuestions,
    us.Upvotes,
    us.Downvotes,
    p.LastEdited,
    p.HistoryComments,
    p.CloseReopenCount
FROM 
    UserStatistics us
LEFT JOIN 
    PopularTags pt ON us.Reputation > (SELECT AVG(Reputation) FROM Users) 
LEFT JOIN 
    PostHistoryDetails p ON us.UserId = p.PostId
WHERE 
    (us.Reputation IS NOT NULL OR us.BadgeCount > 0)
    AND (p.LastEdited IS NULL OR p.LastEdited >= NOW() - INTERVAL '1 year')
ORDER BY 
    us.Reputation DESC, us.BadgeCount DESC, PopularTagCount DESC
LIMIT 100
OFFSET 0;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
   - `UserStatistics`: This aggregates user data, counting badges, accepted questions, and votes.
   - `PopularTags`: This extracts tags that have a high count and are associated with a significant number of posts.
   - `PostHistoryDetails`: This gathers details about post history, focusing on edits and close/reopen counts.

2. **Left Joins**: Used strategically to include even users or tags that may not have related records.

3. **Aggregations**:
   - The query utilizes `COUNT`, `SUM`, and `STRING_AGG` functions to compile comprehensive statistics.

4. **Conditional Logic**: 
   - Employing `COALESCE` to count upvotes/downvotes, accounting for NULL values.

5. **Filters with NULL Logic**:
   - Filtering users to include those with relevant statistics and meeting certain conditions regarding their post history and activity.

6. **Window Function Alternatives**: While there are no explicit window functions used here, the CTEs serve a similar purpose by summarizing data for analytical insights.

7. **Order and Limit**: The query orders the results based on reputation and badge counts, providing insights into the top contributors while limiting the output to the top 100 entries.

This complex query not only benchmarks performance due to its several layers and joins but also presents unique cases where SQL's logic is tested, especially in handling NULL values and complex aggregates.
