
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
        AND p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT tag.TagName, ',') AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        (SELECT value AS TagName, Id FROM STRING_SPLIT(Tags, ',')) AS tag ON tp.PostId = tag.Id
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount
)
SELECT 
    ps.*,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)) AS BadgeCount
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
