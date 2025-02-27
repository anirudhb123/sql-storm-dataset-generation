
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS TagName
                   FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                   WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId, 
        u.DisplayName, pt.Name
),
RankedPosts AS (
    SELECT 
        *,
        @row_num := @row_num + 1 AS Rank
    FROM 
        PostStats, (SELECT @row_num := 0) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    CreationDate,
    LastActivityDate,
    OwnerUserId,
    OwnerDisplayName,
    PostType,
    Tags
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
