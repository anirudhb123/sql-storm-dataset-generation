
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        @row_number := IF(@prev_post_type = pt.Name, @row_number + 1, 1) AS Rank,
        @prev_post_type := pt.Name,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ') FROM Tags t WHERE t.Id IN (SELECT CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS UNSIGNED) FROM (SELECT a.N + b.N * 10 + 1 n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n WHERE n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1))) AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := '') AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
        AND p.Score > 10
        AND p.ViewCount > 100
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.UpVotes,
    rp.DownVotes,
    rp.TagsList
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
