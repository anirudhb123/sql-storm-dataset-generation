WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) AND -- Considering only Questions and Answers
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
top_posts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        CommentCount
    FROM 
        ranked_posts
    WHERE 
        ScoreRank <= 3  -- Top 3 posts per user
)
SELECT 
    t.OwnerDisplayName,
    COUNT(t.PostId) AS TotalPosts,
    SUM(t.CommentCount) AS TotalComments,
    AVG(t.Score) AS AverageScore
FROM 
    top_posts t
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 10;
