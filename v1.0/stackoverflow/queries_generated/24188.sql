WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id
),

PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AnswerCount,
    us.BadgeCount,
    rp.Title,
    rp.ViewCount,
    ph.HistoryTypes,
    pe.CommentCount,
    pe.VoteCount,
    pe.RelatedPostsCount
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
JOIN 
    PostEngagement pe ON rp.PostId = pe.PostId
LEFT JOIN 
    PostHistoryAggregate ph ON rp.PostId = ph.PostId
WHERE 
    us.Reputation > 1000 
    AND rp.UserPostRank = 1 
    AND pe.CommentCount > 5
ORDER BY 
    us.Reputation DESC, 
    rp.ViewCount DESC
LIMIT 10;
This SQL query performs the following operations:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts by score for each user within the last year.
   - `UserStats`: Aggregates statistics for each user relevant to their posts and badges.
   - `PostHistoryAggregate`: Gathers unique post history types and counts the number of editors for each post.
   - `PostEngagement`: Counts comments, votes, and related posts for each post.

2. **Final Selection**:
   - Combines the results from the CTEs to create a robust overview of user activity and post engagement with specific filtering criteria.
   - The `WHERE` clause checks for users with more than 1000 reputation, only takes their top ranked post, and includes additional conditions related to engagement levels.

3. **Ordering and Limiting**: The results are ordered by reputation and view count, limited to the top 10 entries. 

This query incorporates a variety of SQL constructs, demonstrating the use of CTEs, aggregations, joins, and filtering, making it suitable for performance benchmarking and testing complex SQL execution paths.
