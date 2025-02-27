WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), 
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.BadgeCount,
        p.Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.RowNum <= 10
)
SELECT 
    pd.*, 
    STRING_AGG(t.TagName, ', ') AS TagsList
FROM 
    PostDetails pd
LEFT JOIN 
    Tags t ON pd.PostId = t.ExcerptPostId
GROUP BY 
    pd.PostId, pd.Title, pd.Body, pd.CreationDate, pd.Score, pd.ViewCount, pd.OwnerDisplayName, pd.CommentCount, pd.BadgeCount
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
