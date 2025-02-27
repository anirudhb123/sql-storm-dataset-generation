WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
TopRatedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.CommentCount,
    trp.AnswerCount,
    trp.OwnerDisplayName,
    pt.Name AS PostType,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName) AS Tags
FROM 
    TopRatedPosts trp
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = trp.PostId)
LEFT JOIN 
    Tags t ON t.ExcerptPostId = trp.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.ViewCount, trp.CommentCount, trp.AnswerCount, trp.OwnerDisplayName, pt.Name
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
