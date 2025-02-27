
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
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
        FROM Posts p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS tag_names ON p.Id = tag_names.Id
    LEFT JOIN Tags t ON tag_names.tag_name = t.TagName
    WHERE p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.DisplayName, pt.Name
),
TopRankedPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.AnswerCount,
    trp.CommentCount,
    trp.FavoriteCount,
    trp.OwnerDisplayName,
    ua.DisplayName AS UserName,
    ua.TotalVotes,
    ua.UpVotes,
    ua.DownVotes,
    trp.Tags
FROM TopRankedPosts trp
JOIN UserActivity ua ON ua.UserId IN (
    SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId
)
ORDER BY trp.Score DESC, trp.CreationDate DESC;
