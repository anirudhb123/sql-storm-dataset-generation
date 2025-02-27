WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        JSON_AGG(DISTINCT b.Name) AS Badges,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>')  -- Using string matching to get associated tags
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Last year's posts
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id
    HAVING 
        p.ViewCount > 1000  -- Only posts with over 1000 views
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.Tags,
    COALESCE(badge_summary.BadgeCount, 0) AS UniqueBadgeCount,
    COALESCE(vote_summary.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(vote_summary.DownvoteCount, 0) AS DownvoteCount
FROM 
    PostMetrics pm
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        PostId
) AS badge_summary ON pm.PostId = badge_summary.PostId
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) AS vote_summary ON pm.PostId = vote_summary.PostId
ORDER BY 
    pm.ViewCount DESC, 
    pm.Score DESC
LIMIT 50;  -- Limit to top 50 posts based on view count
