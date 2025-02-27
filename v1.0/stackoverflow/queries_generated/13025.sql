-- Performance Benchmarking Query

-- This query retrieves summarized information about the posts, along with user statistics and associated tags.
WITH PostCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE( COUNT(a.Id), 0) AS AnswerCount,
        COALESCE( COUNT(c.Id), 0) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tags ON true  -- This aggregates tags for each post
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM tags) 
    GROUP BY 
        p.Id
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    pc.PostId,
    pc.Title,
    pc.CreationDate,
    pc.Score,
    pc.ViewCount,
    pc.AnswerCount,
    pc.CommentCount,
    pc.Tags,
    us.UserId,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.PostsCount,
    us.TotalViews
FROM 
    PostCounts pc
JOIN 
    Users u ON pc.PostId = u.AccountId  -- Assuming a relation, you may adjust according to actual schema.
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    pc.CreationDate DESC
LIMIT 
    100;  -- Restricts the output to the most recent 100 posts for performance benchmarking.
