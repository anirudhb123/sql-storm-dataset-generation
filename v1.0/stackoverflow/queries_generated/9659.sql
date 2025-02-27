WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        UserId,
        DisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        VoteRank = 1
    ORDER BY 
        Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    u.Reputation,
    b.Name AS BadgeName
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.UserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= NOW() - INTERVAL '1 year'
WHERE 
    b.Class = 1 OR b.Class = 2
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
