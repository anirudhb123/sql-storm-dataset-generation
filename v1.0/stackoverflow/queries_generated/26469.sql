WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS t(TagName) 
    GROUP BY 
        p.Id, u.DisplayName
    HAVING 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, CreationDate, ViewCount, Score, Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) THEN 'Yes'
        ELSE 'No'
    END AS IsUpvoted,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) THEN 'Yes'
        ELSE 'No'
    END AS IsDownvoted,
    pht.Name AS LastEditedType
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
ORDER BY 
    tp.Score DESC;
