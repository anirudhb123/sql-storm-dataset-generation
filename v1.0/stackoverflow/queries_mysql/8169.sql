
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        @rank := IF(@prev_post_type = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @rank := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Owner,
        Rank,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.*,
    COALESCE(b.Name, 'No Badge') AS BadgeEarned
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.Owner = (SELECT DisplayName FROM Users WHERE Id = b.UserId LIMIT 1)
ORDER BY 
    tp.CreationDate DESC;
