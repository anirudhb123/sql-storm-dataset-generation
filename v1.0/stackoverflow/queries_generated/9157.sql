WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TotalComments,
        rp.TotalUpvotes,
        rp.TotalDownvotes,
        rp.RankByUser
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUser = 1 -- Selects only the latest post per user
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.TotalComments,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    u.DisplayName AS OwnerDisplayName,
    b.Name AS BadgeName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= NOW() - INTERVAL '1 YEAR' -- Users with badges from the last year
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC; -- Order by score and then by view count
