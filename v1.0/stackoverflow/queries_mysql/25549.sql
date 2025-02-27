
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        @rank := IF(@postTypeId = p.PostTypeId, @rank + 1, 1) AS Rank,
        @postTypeId := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN 
        (SELECT @rank := 0, @postTypeId := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    GROUP_CONCAT(DISTINCT tag.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
    FROM 
        Posts p
    CROSS JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
              (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
    WHERE 
        p.Tags IS NOT NULL) AS tag ON tp.PostId = tag.PostId
GROUP BY 
    tp.Title, 
    tp.CreationDate, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.CommentCount, 
    u.DisplayName, 
    u.Reputation
ORDER BY 
    tp.UpVotes DESC, 
    tp.CommentCount DESC;
