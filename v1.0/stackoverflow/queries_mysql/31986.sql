
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS UserRank,
        @current_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.N), ',', -1)) AS TagName
         FROM (SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.N - 1) AS t ON TRUE
    CROSS JOIN (SELECT @row_number := 0, @current_user_id := NULL) AS vars
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UserRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Deletions,
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1 
        AND rp.Score > 10 
        AND rp.CommentCount > 5
)

SELECT 
    f.Id,
    f.Title,
    f.CreationDate,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.Deletions,
    COALESCE(NULLIF(SUBSTRING_INDEX(f.TagList, ',', 1), ''), 'No Tags') AS FirstTag
FROM 
    FilteredPosts f
LEFT JOIN 
    Users u ON f.Id = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
