
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id
), 
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag 
         FROM Posts p 
         JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - 
         CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
    JOIN 
        Tags t ON tag.tag = t.TagName
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    COALESCE(ps.CommentCount, 0) AS Comments,
    COALESCE(ps.VoteCount, 0) AS Votes,
    COALESCE(ps.UpVoteCount, 0) AS UpVotes,
    COALESCE(ps.DownVoteCount, 0) AS DownVotes,
    pwt.Tags,
    CASE 
        WHEN ps.LastActivity IS NOT NULL THEN 
            TIMESTAMPDIFF(SECOND, ps.LastActivity, CAST('2024-10-01 12:34:56' AS DATETIME)) / 3600 
        ELSE NULL 
    END AS HoursSinceLastActivity
FROM 
    PostStats ps
LEFT JOIN 
    PostWithTags pwt ON ps.PostId = pwt.PostId
WHERE 
    ps.CommentCount > 5 OR ps.VoteCount > 10
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC
LIMIT 100;
