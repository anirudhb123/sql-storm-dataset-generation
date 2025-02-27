WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserVoteDetails AS (
    SELECT 
        v.PostId,
        MAX(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVote,
        MAX(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVote
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.Title AS PostTitle,
    p.ViewCount,
    p.Score,
    COALESCE(uv.UpVote, 0) AS UpVoteCount,
    COALESCE(uv.DownVote, 0) AS DownVoteCount,
    RANK() OVER (ORDER BY p.Score DESC) AS GlobalScoreRank,
    b.BadgeCount AS UserBadgeCount,
    b.Badges AS UserBadgeNames
FROM 
    RankedPosts p
LEFT JOIN 
    UserVoteDetails uv ON p.PostId = uv.PostId
LEFT JOIN 
    Posts cp ON p.PostId = cp.AcceptedAnswerId
LEFT JOIN 
    BadgeSummary b ON cp.OwnerUserId = b.UserId
WHERE 
    p.RankByViews <= 5 AND 
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId) > 10
    AND p.PostId IS NOT NULL
ORDER BY 
    GlobalScoreRank,
    p.ViewCount DESC;

This SQL query performs the following operations:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts from the last year based on view count and score.
   - `UserVoteDetails`: Aggregates voting data for posts to find upvotes and downvotes.
   - `BadgeSummary`: Counts badges and concatenates their names for users.

2. **Main Query**:
   - Joins various CTEs to gather information on posts, user votes, and user badges.
   - Uses `COALESCE` to handle NULL values in votes.
   - Filters posts to consider only the top 5 posts by view count that have over 10 comments.
   - Orders results by global score rank and view count.

3. **Specifications**:
   - The SQL demonstrates use of ranking functions (`ROW_NUMBER`, `DENSE_RANK`, `RANK`), aggregation (`COUNT`, `STRING_AGG`), conditional logic, and outer joins, showcasing a complex and nuanced query suitable for performance benchmarking.
