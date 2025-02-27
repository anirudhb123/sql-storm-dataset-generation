
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        @rownum := @rownum + 1 AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
               , (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
              ) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    CROSS JOIN (SELECT @userRank := 0) r
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        pt.Name AS EditType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL 1 MONTH
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.Tags,
    u.UserId,
    u.DisplayName AS ActiveUser,
    u.VoteCount,
    u.UpVotes,
    u.DownVotes,
    ph.Editor AS LastEditedBy,
    ph.EditDate AS LastEditDate,
    ph.EditType AS LastEditType
FROM 
    RankedPosts r
JOIN 
    (SELECT *, UserRank FROM TopActiveUsers WHERE UserRank <= 10) u ON u.UserRank <= 10 
LEFT JOIN 
    RecentPostHistory ph ON r.PostId = ph.PostId
WHERE 
    r.Rank <= 50 
ORDER BY 
    r.CreationDate DESC;
