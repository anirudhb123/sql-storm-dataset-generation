
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(DISTINCT com.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(tag) AS tag FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS tag
          FROM Posts p
          JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
          ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1) tag_elements) AS tag_elements ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_elements.tag)
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName
),
RankedPosts AS (
    SELECT 
        ps.*,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats ps, (SELECT @rank := 0) r
    ORDER BY 
        ps.Score DESC, ps.ViewCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Tags,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
