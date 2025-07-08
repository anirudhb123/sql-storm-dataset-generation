
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        LISTAGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.TagName IN (SELECT value FROM TABLE(FLATTEN(INPUT => SPLIT(p.Tags, '<>'))))
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        CommentCount,
        Tags,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.Tags,
    CASE 
        WHEN p.Rank <= 10 THEN 'Top 10'
        WHEN p.Rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS RankCategory
FROM 
    PostStatistics p
ORDER BY 
    p.Rank
LIMIT 100;
