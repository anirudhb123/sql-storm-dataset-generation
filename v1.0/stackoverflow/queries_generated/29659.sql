WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        row_number() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC;

This query benchmarks string processing by ranking the top 5 posts from each post type within the last year based on the score, then joins relevant information about the post owner, counts the comments, and the number of answers related to each post. The results are organized by creation date in descending order, providing an insight into the most talked-about topics and users in recent time.
