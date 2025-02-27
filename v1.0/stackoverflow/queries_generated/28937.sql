WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(sp.AvgScore, 0) AS AvgScore,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            postId,
            AVG(Score) AS AvgScore
        FROM 
            Comments
        GROUP BY 
            postId
    ) sp ON p.Id = sp.postId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerDisplayName, p.CreationDate, p.Score, p.ViewCount, sp.AvgScore
),
StringProcessed AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rl.TagList,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rg.TagRank,
        CASE 
            WHEN rp.Score > 5 THEN 'High Score'
            ELSE 'Normal Score'
        END AS ScoreCategory
    FROM
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            postId,
            STRING_AGG(Tags, ', ') AS TagList
        FROM 
            Posts
        GROUP BY 
            postId
    ) rl ON rp.PostId = rl.postId
    LEFT JOIN (
        SELECT 
            Tags,
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS TagRank
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
        GROUP BY 
            Tags
    ) rg ON rg.Tags = rp.Tags
)
SELECT 
    sp.PostId,
    sp.Title,
    sp.TagList,
    sp.CreationDate,
    sp.Score,
    sp.CommentCount,
    sp.ScoreCategory,
    CASE 
        WHEN CHARINDEX('SQL', sp.Title) > 0 THEN 'SQL Specialist'
        ELSE 'General'
    END AS TitleCategory
FROM 
    StringProcessed sp
WHERE 
    sp.ScoreCategory = 'High Score'
ORDER BY 
    sp.CommentCount DESC, 
    sp.CreationDate DESC
LIMIT 10;
