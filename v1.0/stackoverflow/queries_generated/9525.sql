WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC, p.Score DESC) AS RankByPopularity
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        RankByPopularity <= 10
), 
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.OwnerDisplayName,
        COALESCE(MAX(pht.CreationDate), 'No History') AS LastEditDate,
        COUNT(DISTINCT pht.PostHistoryTypeId) AS HistoryEntryCount,
        STRING_AGG(DISTINCT CONCAT(pt.Name, ': ', COALESCE(t.TagName, 'No Tags')), ', ') AS TagsAssociated
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory pht ON tp.PostId = pht.PostId
    LEFT JOIN 
        Posts p ON p.Id = tp.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag) 
    LEFT JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    GROUP BY 
        tp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.LastEditDate,
    pd.HistoryEntryCount,
    pd.TagsAssociated
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC;
