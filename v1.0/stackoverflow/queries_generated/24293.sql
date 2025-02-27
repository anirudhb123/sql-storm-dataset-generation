WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate,
        CASE 
            WHEN Reputation IS NULL THEN 0 
            ELSE Reputation 
        END AS EffectiveReputation
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(ph.Comment, 'No historical comments') AS HistoryComment,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > DATEADD(year, -1, CURRENT_TIMESTAMP)
    GROUP BY p.Id, ph.Comment
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpvoteCount,
        ur.EffectiveReputation,
        DENSE_RANK() OVER (PARTITION BY ur.EffectiveReputation ORDER BY pd.UpvoteCount DESC) AS ReputationRank
    FROM PostDetails pd
    INNER JOIN UserReputation ur ON pd.OwnerUserId = ur.UserId
    WHERE pd.CommentCount > 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.EffectiveReputation,
    CASE 
        WHEN tp.ReputationRank = 1 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostCategory,
    (SELECT STRING_AGG(DISTINCT 'Comment by user: ' || COALESCE(c.UserDisplayName, 'Anonymous'), '; ') 
     FROM Comments c 
     WHERE c.PostId = tp.PostId) AS UserComments
FROM TopPosts tp
WHERE tp.ReputationRank <= 3
ORDER BY tp.EffectiveReputation DESC, tp.UpvoteCount DESC;

### Explanation:
1. **CTEs**: Two Common Table Expressions (CTEs) `UserReputation` and `PostDetails` gather necessary data for reputation and post attributes, including their effective reputation and historical comments.
2. **Historical Comments**: `COALESCE` is used to provide a default message if there are no comments associated with the post history.
3. **Grouping and Counting**: The query groups posts by user to count comments and upvotes.
4. **DENSE_RANK**: Used to rank posts based on upvote count among users with the same effective reputation.
5. **Conditional Logic**: The final SELECT statement categorizes posts based on their ranking and includes a subquery to aggregate comment information per post with `STRING_AGG`.
6. **Filtering**: Only posts with more than 5 comments and those with the top 3 ranks in their respective reputation groups are selected. 

This SQL query showcases various constructs like CTEs, window functions, aggregate functions, and conditional logic, while also leveraging string manipulation and NULL handling. It aims to return a useful summary of popular posts with additional contextual information.
