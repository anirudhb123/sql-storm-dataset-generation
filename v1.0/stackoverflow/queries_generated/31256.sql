WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1  -- Gold badges only
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.OwnerDisplayName,
        RANK() OVER (ORDER BY ps.Score DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    t.Title,
    t.Score,
    t.CommentCount,
    t.VoteCount,
    t.UpVoteCount,
    t.DownVoteCount,
    t.OwnerDisplayName,
    ub.BadgeName,
    ub.BadgeRank
FROM 
    TopPosts t
LEFT JOIN 
    UserBadges ub ON t.OwnerDisplayName = ub.DisplayName
WHERE 
    t.Rank <= 10  -- Top 10 posts
ORDER BY 
    t.Score DESC, ub.BadgeRank ASC NULLS LAST;

This query accomplishes the following:

1. **Recursive CTE (`UserBadges`)**: Collects users and their gold badges, ranking them by the date they received the badge.
  
2. **Aggregated Post Statistics (`PostStatistics`)**: Gathers statistics for each post such as comment count, vote count, and differentiates between upvotes and downvotes over the last year.

3. **Top Posts Extraction (`TopPosts`)**: Ranks these posts based on their score.

4. **Final Selection**: Joins the top posts with user badges, filtering down to the top 10 posts and ordering them by score while ensuring badge rank is considered.

This query uses constructs such as window functions, outer joins, CTEs, and complicated predicates, making it suitable for performance benchmarking in a rich schema environment.
