WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        U.DisplayName AS Owner,
        COUNT(DISTINCT C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, U.DisplayName
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Owner
    FROM 
        RankedPosts rp
    WHERE
        rp.PostRank = 1
    ORDER BY 
        rp.Score DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.Owner,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
    COUNT(B.Id) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Votes V ON tp.PostId = V.PostId AND V.VoteTypeId = 8 -- BountyStart
LEFT JOIN 
    Badges B ON B.UserId = tp.Owner AND B.Date >= NOW() - INTERVAL '1 year'
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.Owner
ORDER BY 
    tp.Score DESC;
