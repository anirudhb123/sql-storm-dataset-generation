
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes
FROM 
    TopPosts t
JOIN 
    PostHistory ph ON t.PostId = ph.PostId 
WHERE 
    ph.CreationDate >= DATEADD(day, -60, '2024-10-01 12:34:56') 
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
