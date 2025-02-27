WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
TopPosts AS (
    SELECT PostId, Title, Score, ViewCount
    FROM RankedPosts
    WHERE Rank <= 10
),
PostVoteCount AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostWithBadges AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM TopPosts p
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS Count
        FROM Badges
        GROUP BY UserId
    ) b ON b.UserId = (
        SELECT OwnerUserId FROM Posts WHERE Id = p.PostId
    )
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' 
            ELSE NULL END, ', ') AS HistoryTypes
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        p.BadgeCount,
        ph.HistoryCount,
        COALESCE(ph.HistoryTypes, 'No History') AS HistoryInfo,
        CASE 
            WHEN p.Score >= 100 THEN 'Highly Rated'
            WHEN p.Score BETWEEN 50 AND 99 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS RatingCategory
    FROM PostWithBadges p
    LEFT JOIN PostHistoryStats ph ON p.PostId = ph.PostId
)
SELECT 
    Title,
    Score,
    ViewCount,
    BadgeCount,
    HistoryCount,
    HistoryInfo,
    RatingCategory
FROM FinalResults
WHERE BadgeCount > 0
ORDER BY Score DESC, ViewCount DESC;

This SQL query performs multiple operations to fetch the top posts of the past year along with various statistics:

1. **CTEs**: It uses Common Table Expressions (CTEs) for organization, making it easier to read and maintain.
2. **Window Functions**: A window function `ROW_NUMBER()` ranks posts based on their scores within their post type.
3. **Subqueries**: Includes correlated subqueries to find related users for badge counts, linking them to post ownership.
4. **Case Expressions**: It also uses `CASE` statements to classify posts into categories based on score.
5. **Aggregation**: It uses `STRING_AGG` to provide a list of post history types associated with each post.
6. **Filtering**: The final result set filters only those posts that have badges, ensuring they meet a specified condition.
7. **Handling NULLs**: The `COALESCE` function is utilized to handle NULL values gracefully.

The query presents a comprehensive overview of popular posts on a platform, reflecting user engagement and moderation history, while also highlighting posts with badges for added interest.
