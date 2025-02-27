
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_partition = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_partition := p.PostTypeId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_partition := NULL) AS vars
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
DetailedPostInfo AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.OwnerDisplayName,
        trp.CommentCount,
        COALESCE(pht.Name, 'No History') AS PostHistoryType
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostHistory ph ON trp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    ORDER BY 
        trp.Score DESC
)
SELECT 
    dpi.Title,
    dpi.OwnerDisplayName,
    dpi.Score,
    dpi.ViewCount,
    dpi.CommentCount,
    GROUP_CONCAT(DISTINCT dpi.PostHistoryType ORDER BY dpi.PostHistoryType ASC SEPARATOR ', ') AS PostHistoryTypes
FROM 
    DetailedPostInfo dpi
GROUP BY 
    dpi.Title, dpi.OwnerDisplayName, dpi.Score, dpi.ViewCount, dpi.CommentCount
ORDER BY 
    dpi.Score DESC;
