
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01 12:34:56') AS DATETIME)
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
    STRING_AGG(DISTINCT tag.TagName, ',') AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') AS TagName
    FROM 
        Posts p
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
