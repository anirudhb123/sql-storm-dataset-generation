WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        cp.CommentsCount,
        COALESCE(bp.BadgesCount, 0) AS BadgesCount,
        p.Tags
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentsCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cp ON tp.PostId = cp.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgesCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) bp ON tp.OwnerDisplayName = bp.UserId
    JOIN 
        Posts p ON p.Id = tp.PostId
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.ViewCount,
    pd.CommentsCount,
    pd.BadgesCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '><')) AS tag ON tag IS NOT NULL
JOIN 
    Tags t ON t.TagName = tag
GROUP BY 
    pd.Title, pd.OwnerDisplayName, pd.Score, pd.ViewCount, pd.CommentsCount, pd.BadgesCount
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
