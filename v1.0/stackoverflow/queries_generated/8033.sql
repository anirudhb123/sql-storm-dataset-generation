WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score,
        u.DisplayName AS OwnerDisplayName, 
        u.Reputation AS OwnerReputation,
        bc.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) bc ON u.Id = bc.UserId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.ViewCount, 
    tp.Score, 
    tp.OwnerDisplayName, 
    tp.OwnerReputation, 
    COALESCE(tp.BadgeCount, 0) AS BadgeCount,
    JSON_AGG(DISTINCT c.Text) AS Comments,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    Votes v ON v.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.OwnerReputation, tp.BadgeCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
