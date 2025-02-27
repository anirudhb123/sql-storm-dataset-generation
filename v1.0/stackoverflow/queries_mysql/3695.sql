
WITH PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes
    FROM 
        PostScore ps
    WHERE 
        ps.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT AVG(COALESCE(Owner.Reputation, 0)) 
     FROM Users Owner 
     JOIN Posts p ON p.OwnerUserId = Owner.Id 
     WHERE p.Id = tp.PostId) AS AverageOwnerReputation,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') 
     FROM Tags t 
     JOIN (
         SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag 
         FROM Posts p
         INNER JOIN (
             SELECT a.N FROM (SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
             SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
             SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) a 
             ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
         WHERE p.Id = tp.PostId
     ) tags ON t.TagName = tags.tag) AS TagsList
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
