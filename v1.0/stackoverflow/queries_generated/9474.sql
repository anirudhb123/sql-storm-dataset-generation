WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    (SELECT COUNT(DISTINCT v.UserId) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(DISTINCT v.UserId) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVoteCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     INNER JOIN 
         (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag) AS post_tags 
     ON post_tags.tag = t.TagName 
     WHERE t.WikiPostId = tp.PostId) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
