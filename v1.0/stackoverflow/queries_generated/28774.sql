WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- top 10 posts per type
)
SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.Tags,
    f.OwnerDisplayName,
    f.CommentCount,
    f.AnswerCount,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames,
    CASE 
        WHEN f.Rank = 1 THEN 'Top'
        ELSE 'Other'
    END AS RankCategory
FROM 
    FilteredPosts f
JOIN 
    PostTypes pt ON f.PostTypeId = pt.Id
GROUP BY 
    f.PostId, f.Title, f.Body, f.CreationDate, f.Score, f.ViewCount, f.Tags, f.OwnerDisplayName, f.CommentCount, f.AnswerCount, f.Rank
ORDER BY 
    f.Score DESC, f.CreationDate DESC;
