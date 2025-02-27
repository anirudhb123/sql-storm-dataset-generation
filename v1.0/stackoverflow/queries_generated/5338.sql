WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT v.UserId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(DISTINCT v.UserId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        pt.Name AS PostType,
        ht.Name AS HistoryType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
)
SELECT 
    pa.OwnerDisplayName,
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    COUNT(DISTINCT ht.Name) AS HistoryTypeCount
FROM 
    PostActivity pa
LEFT JOIN 
    PostHistory h ON pa.PostId = h.PostId
GROUP BY 
    pa.OwnerDisplayName, pa.Title, pa.Score, pa.ViewCount, pa.CommentCount, pa.UpVoteCount, pa.DownVoteCount
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC
LIMIT 100;
