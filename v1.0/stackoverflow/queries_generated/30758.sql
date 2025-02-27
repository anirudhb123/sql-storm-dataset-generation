WITH RECURSIVE UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
),
CommentStats AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Editing title, body or tags
    GROUP BY 
        ph.PostId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.Rank,
    p.Title,
    p.ViewCount,
    p.Tags,
    ps.CommentCount,
    ps.AvgCommentScore,
    phs.EditCount,
    phs.LastEditDate
FROM 
    UserRankings ur
JOIN 
    PostsWithTags p ON ur.UserId = p.OwnerUserId
LEFT JOIN 
    CommentStats ps ON p.PostId = ps.PostId
LEFT JOIN 
    PostHistoryStats phs ON p.PostId = phs.PostId
WHERE 
    ur.Rank <= 10  -- Get top 10 users based on reputation
    AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts)  -- Posts with above average views
ORDER BY 
    ur.Reputation DESC;
This SQL query constructs a performance benchmarking task by utilizing various SQL features such as Common Table Expressions (CTEs), string aggregation, window functions, and complex joins to analyze user performance on posts in a StackOverflow-like schema. It retrieves top users based on reputation together with insights about their highly viewed posts, including tags, comment statistics, and post edit history.
