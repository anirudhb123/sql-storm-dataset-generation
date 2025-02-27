WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, Score, Body, Tags, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.OwnerDisplayName,
    CASE 
        WHEN tp.Score > 100 THEN 'High Score'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    LENGTH(tp.Body) AS BodyLength,
    (SELECT COUNT(CASE WHEN ph.PostId = tp.PostId THEN 1 END) 
     FROM PostHistory ph 
     WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS ClosureHistory
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
