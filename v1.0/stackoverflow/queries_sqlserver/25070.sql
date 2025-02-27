
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '>') AS tag_name ON 1=1
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.value
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Score
),

TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC;
