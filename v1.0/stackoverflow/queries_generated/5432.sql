WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.RankByScore = 1 AND rp.OwnerUserId = u.Id
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.OwnerDisplayName,
    pht.Name AS PostHistoryType
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    tp.UpVoteCount DESC, tp.ViewCount DESC;
