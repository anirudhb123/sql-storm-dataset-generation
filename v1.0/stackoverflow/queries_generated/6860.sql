WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AwardedAnswerId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, CreationDate, UpVoteCount, DownVoteCount, Rank 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.UpVoteCount,
    tp.DownVoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Posts p 
     JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
     WHERE p.Id = tp.PostId) AS Tags
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.ViewCount DESC;
