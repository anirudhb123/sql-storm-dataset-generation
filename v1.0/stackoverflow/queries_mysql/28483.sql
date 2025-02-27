
WITH RankedPosts AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        @rank := @rank + 1 AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '<', -1) AS TagName
        FROM
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) t ON true
    CROSS JOIN (SELECT @rank := 0) r
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
TopQuestions AS (
    SELECT
        p.PostID,
        p.Title,
        p.OwnerDisplayName,
        p.Score,
        p.CommentCount,
        p.Tags
    FROM RankedPosts p
    WHERE p.Rank <= 10  
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.Score,
    tq.CommentCount,
    tq.Tags,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes
FROM TopQuestions tq
LEFT JOIN VoteStats vs ON tq.PostID = vs.PostId
ORDER BY tq.Score DESC;
