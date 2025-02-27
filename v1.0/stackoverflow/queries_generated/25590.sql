WITH ranked_posts AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS author_name,
        COUNT(DISTINCT c.Id) AS comment_count,
        COUNT(DISTINCT v.Id) AS vote_count,
        STRING_AGG(DISTINCT t.TagName, ', ') AS tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT v.Id) DESC) AS author_rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- considering only upvotes
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array::varchar = t.TagName
    GROUP BY 
        p.Id, u.Id
), post_metrics AS (
    SELECT 
        post_id,
        Title,
        CreationDate,
        author_name,
        comment_count,
        vote_count,
        tags,
        author_rank,
        RANK() OVER (ORDER BY vote_count DESC) AS global_rank
    FROM 
        ranked_posts
)
SELECT 
    pm.post_id,
    pm.Title,
    pm.CreationDate,
    pm.author_name,
    pm.comment_count,
    pm.vote_count,
    pm.tags,
    pm.author_rank,
    pm.global_rank,
    (SELECT COUNT(*) FROM Posts AS inner_posts WHERE inner_posts.CreationDate < pm.CreationDate) AS older_posts_count,
    (SELECT MIN(CreationDate) FROM Posts) AS oldest_post_date
FROM 
    post_metrics pm
WHERE 
    pm.author_rank <= 5 -- getting top 5 posts by each user
ORDER BY 
    pm.global_rank, pm.CreationDate DESC;
