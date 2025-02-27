
WITH TagFilter AS (
    SELECT DISTINCT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        p.Id AS PostId
    FROM Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT a.Id), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId 
        AND a.PostTypeId = 2 
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY p.Id, p.Title, p.ViewCount
),
RankedPosts AS (
    SELECT 
        pm.*,
        @row_number := IF(@prev_votes = (pm.UpVotes - pm.DownVotes), @row_number, @row_number + 1) AS RankPosition,
        @prev_votes := (pm.UpVotes - pm.DownVotes)
    FROM PostMetrics pm, (SELECT @row_number := 0, @prev_votes := NULL) AS vars
    ORDER BY pm.UpVotes - pm.DownVotes DESC, pm.ViewCount DESC
)
SELECT 
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.UpVotes,
    p.DownVotes,
    tg.TagName
FROM RankedPosts p
JOIN TagFilter tg ON p.PostId = tg.PostId
WHERE p.RankPosition <= 10
ORDER BY p.RankPosition, tg.TagName;
