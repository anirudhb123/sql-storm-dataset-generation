WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.OwnerUserId,
        a.Title,
        a.CreationDate,
        a.PostTypeId,
        a.AcceptedAnswerId,
        a.ParentId,
        Level + 1
    FROM Posts a
    INNER JOIN RecursivePostCTE r ON r.PostId = a.ParentId
    WHERE a.PostTypeId = 2 -- Only Answers
),
LatestPostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.LastActivityDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.LastActivityDate >= (NOW() - INTERVAL '30 days')
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        p.Title AS PostTitle,
        ph.CreationDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted'
            ELSE 'Edited'
        END AS HistoryAction
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
)
SELECT 
    UP.DisplayName AS UserName,
    LPA.Title AS PostTitle,
    LPA.ViewCount,
    COUNT(DISTINCT PD.UserId) AS EditCount,
    COALESCE(SUM(CASE WHEN PD.HistoryAction = 'Closed' THEN 1 ELSE 0 END), 0) AS ClosedCount,
    COALESCE(SUM(CASE WHEN PD.HistoryAction = 'Deleted' THEN 1 ELSE 0 END), 0) AS DeletedCount,
    SUM(CASE WHEN LPA.LastVoteDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
    ROW_NUMBER() OVER (ORDER BY LPA.ViewCount DESC) AS Rank
FROM LatestPostActivity LPA
JOIN Users UP ON UP.Id = LPA.OwnerUserId
LEFT JOIN PostHistoryDetails PD ON PD.PostId = LPA.Id
GROUP BY UP.DisplayName, LPA.Title, LPA.ViewCount
HAVING COUNT(DISTINCT PD.UserId) > 0
ORDER BY Rank
LIMIT 10
OFFSET 0;

This SQL query performs the following actions:

1. **Recursive CTE (`RecursivePostCTE`)**: Fetches questions and their corresponding answers in a hierarchical structure.
2. **Latest Post Activity CTE (`LatestPostActivity`)**: Calculates details for posts that had activity in the last 30 days, including comment counts and last vote dates.
3. **Post History Details CTE (`PostHistoryDetails`)**: Joins post history to the posts to categorize actions as 'Closed', 'Deleted', or 'Edited'.
4. **Main Select Query**: Aggregates data about posts, grouping by users and including various counts related to edits and historical actions. It also ranks the posts by view count.

This query is designed to benchmark performance with complex joins, use of CTEs, window functions, and groupings that encapsulate various expressions, including conditional logic.
