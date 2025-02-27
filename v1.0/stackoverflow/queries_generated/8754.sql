WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        pt.Name AS PostTypeName,
        vt.Name AS VoteTypeName,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName, pt.Name
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.CreationDate,
    tpd.ViewCount,
    tpd.Score,
    tpd.OwnerDisplayName,
    tpd.PostTypeName,
    tpd.VoteCount
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, 
    tpd.ViewCount DESC;
