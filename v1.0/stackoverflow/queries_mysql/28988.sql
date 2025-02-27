
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT 
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS t ON p.Id = t.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.PostTypeId
),

PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        Tags,
        Rank
    FROM RankedPosts
    WHERE Rank <= 10 
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.Tags,
    ue.UserId,
    ue.DisplayName,
    ue.VoteCount,
    ue.UpVotes,
    ue.DownVotes
FROM PostStatistics ps
JOIN UserEngagement ue ON ps.PostId = ue.UserId
ORDER BY ps.CreationDate DESC, ps.Score DESC;
