WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Count only upvotes and downvotes
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts from the last 30 days
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per type
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    COALESCE(CAST(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS INT), 0) AS ClosedCount,
    COALESCE(CAST(SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS INT), 0) AS DeletedCount,
    COALESCE(CAST(SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS INT), 0) AS EditedCount
FROM 
    TopPosts p
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId
GROUP BY 
    p.Title, p.OwnerDisplayName
ORDER BY 
    COALESCE(CLOSED_COUNT, 0) DESC, 
    COALESCE(EDITED_COUNT, 0) DESC;
