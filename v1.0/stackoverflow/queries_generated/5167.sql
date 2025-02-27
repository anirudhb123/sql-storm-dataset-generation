WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    u.DisplayName AS OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    bt.Name AS BadgeName,
    bt.Class AS BadgeClass
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges bt ON u.Id = bt.UserId
WHERE 
    bt.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = u.Id)
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
