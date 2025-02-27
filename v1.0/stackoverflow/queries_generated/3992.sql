WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN <= 5
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    ISNULL(pv.TotalVotes, 0) AS TotalVotes,
    ISNULL(pv.Upvotes, 0) AS Upvotes,
    ISNULL(pv.Downvotes, 0) AS Downvotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(b.Id) > 0
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OPTION (RECOMPILE);
