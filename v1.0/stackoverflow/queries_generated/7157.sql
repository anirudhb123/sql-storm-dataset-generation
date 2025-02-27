WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS Author, 
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        * 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Author, 
    tp.CommentCount, 
    tp.UpVotes, 
    tp.DownVotes,
    COALESCE(SUM(b.Class), 0) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.Author = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    STRING_SPLIT((SELECT Tags FROM Posts WHERE Id = tp.PostId), ',') AS t ON t.value = t.TagName
GROUP BY 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Author, 
    tp.CommentCount, 
    tp.UpVotes, 
    tp.DownVotes
ORDER BY 
    tp.CreationDate DESC;
