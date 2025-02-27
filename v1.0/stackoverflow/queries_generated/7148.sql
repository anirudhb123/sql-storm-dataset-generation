WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Views,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Views,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.Views,
        tp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        TopPosts tp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.Views, tp.OwnerDisplayName
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.Views,
    ps.OwnerDisplayName,
    ps.TotalComments,
    ps.TotalBounties,
    pht.Name AS PostHistoryType
FROM 
    PostStats ps
LEFT JOIN 
    PostHistory ph ON ps.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = ps.PostId)
ORDER BY 
    ps.Score DESC, ps.Views DESC;
