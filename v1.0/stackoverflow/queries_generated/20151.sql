WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(CAST(p.ClosedDate AS DATE), '9999-12-31') AS ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY u.LastAccessDate ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= DATEADD(year, -1, GETDATE())
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        GROUP_CONCAT(pt.Name) AS HistoryTypes,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY ph.PostId, ph.UserId
),
FinalPostInfo AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.Body,
        pi.OwnerReputation,
        pi.CommentCount,
        pi.UpvoteCount,
        pi.DownvoteCount,
        pi.ClosedDate,
        ph.HistoryTypes,
        ph.HistoryCount,
        CASE 
            WHEN pi.ClosedDate < GETDATE() THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM PostInfo pi
    LEFT JOIN PostHistoryInfo ph ON pi.PostId = ph.PostId
    WHERE pi.rn <= 10
)
SELECT 
    PostId,
    Title,
    Body,
    OwnerReputation,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    HistoryTypes,
    HistoryCount,
    PostStatus
FROM FinalPostInfo
WHERE 
    (ClosedDate = '9999-12-31' OR ClosedDate > GETDATE())
    AND (OwnerReputation > 100 OR HistoryCount > 5)
ORDER BY 
    CASE 
        WHEN PostStatus = 'Active' THEN 1
        ELSE 2
    END,
    UpvoteCount DESC;

This SQL query does the following:

1. **CTEs**:
   - The `PostInfo` CTE aggregates information for posts created in the last year including owner reputation and number of comments and votes.
   - The `PostHistoryInfo` CTE aggregates historical edits or changes made to each post in the last six months.
   - The `FinalPostInfo` CTE combines the above information and computes the status of each post as either 'Closed' or 'Active'.

2. **Joins and Subqueries**:
   - Uses `LEFT JOIN` to combine historical data with current post information.
   - Utilizes subqueries to calculate counts of comments and votes directly related to each post.

3. **WHERE Clause**:
   - Includes a complex condition to filter on the closed date of posts, as well as the owner's reputation or the history count of post modifications.

4. **Window Functions**:
   - The `ROW_NUMBER()` window function is used to rank the posts per user by creation date.

5. **String Aggregation**:
   - Uses `GROUP_CONCAT` to compile all the post history types into a single string per post.

6. **Conditional Logic**:
   - Utilizes `COALESCE` for handling potential `NULL` values in the `ClosedDate`, and a `CASE` statement to denote the status of the post.

This SQL query aims to not only retrieve top posts based on specific criteria but also includes a variety of SQL features showcasing its complexity ideal for performance benchmarking.
