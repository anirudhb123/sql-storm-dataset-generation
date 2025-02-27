WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    (
        SELECT 
            AVG(Score) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = tp.PostId 
            AND v.VoteTypeId = 2 -- UpMod 
    ) AS AverageUpvotes,
    (
        SELECT 
            COUNT(*) 
        FROM 
            PostHistory ph 
        WHERE 
            ph.PostId = tp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted statuses
    ) AS StatusChanges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
