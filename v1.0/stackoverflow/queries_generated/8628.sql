WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.UpVotes, 
        rp.DownVotes, 
        rp.CommentCount, 
        rp.HistoryCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUser = 1
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.Score,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.HistoryCount,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName, tp.Title, tp.Score, tp.UpVotes, tp.DownVotes, tp.CommentCount, tp.HistoryCount
ORDER BY 
    tp.Score DESC, u.DisplayName;
