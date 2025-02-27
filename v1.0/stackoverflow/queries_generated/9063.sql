WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount, 
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '90 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    pt.Name AS PostTypeName,
    JSON_AGG(B.Name) AS BadgeNames
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, 
    tp.Title, 
    tp.OwnerDisplayName, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
