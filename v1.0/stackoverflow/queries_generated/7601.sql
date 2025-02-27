WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId = 1
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title, 
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.AnswerCount,
        trp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON trp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            u.Id AS UserId, 
            COUNT(b.Id) AS BadgeCount
        FROM 
            Users u 
        JOIN 
            Badges b ON u.Id = b.UserId 
        GROUP BY 
            u.Id
    ) b ON trp.OwnerDisplayName = b.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.BadgeCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.CommentCount DESC
LIMIT 10;
