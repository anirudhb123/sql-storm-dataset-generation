WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
           COALESCE(NULLIF(p.Body, ''), 'No content available') AS BodyContent,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM Posts p
    LEFT JOIN Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserPostStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT ph.PostId,
           ph.CreationDate AS CloseDate,
           ph.UserDisplayName,
           pt.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE pt.Name IN ('Post Closed', 'Post Reopened')
)
SELECT 
    up.DisplayName AS UserName,
    up.PostCount,
    up.TotalScore,
    up.AvgScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.TagsList,
    ph.CloseDate,
    ph.PostHistoryType
FROM UserPostStats up
JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN ClosedPostHistory ph ON rp.PostId = ph.PostId
WHERE up.PostCount > 5
  AND rp.ScoreRank = 1
  AND (ph.CloseDate IS NULL OR ph.CloseDate >= NOW() - INTERVAL '30 days')
ORDER BY up.TotalScore DESC, rp.CreationDate ASC
LIMIT 100
OFFSET 0;

This SQL query achieves multiple complexities by:
1. Utilizing Common Table Expressions (CTEs) to break down the logic step by step.
2. Applying the `ROW_NUMBER()` window function to rank posts by score per user.
3. Using a string aggregation function `STRING_AGG()` to compile tags for each post.
4. Implementing outer joins to include users with no posts and handling cases where content may be empty or null.
5. Incorporating complicated filters in the main query to only include users with more than 5 posts, the highest scoring post, and considering the closing status of posts over the last month.
6. Applying filtering conditions on the timestamps to analyze recent activity.
7. Utilizing COALESCE to ensure that nulls are handled gracefully while summing and averaging scores.
8. Final output ordering and pagination to allow for efficient result handling.
