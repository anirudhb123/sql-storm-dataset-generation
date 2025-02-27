
WITH LatestPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate AS PostCreationDate, 
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE NULL END), 0) AS AverageUpVotes, 
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 AS n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
               CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) ) AS tag_name ON tag_name.tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.tag
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostScores AS (
    SELECT 
        lp.PostId,
        lp.Title,
        lp.OwnerDisplayName,
        lp.PostCreationDate,
        lp.ViewCount,
        lp.AverageUpVotes,
        lp.CommentCount,
        lp.Tags,
        COALESCE(SUM(CASE WHEN phs.EditCount > 0 THEN phs.EditCount END), 0) AS TotalEdits
    FROM 
        LatestPosts lp
    LEFT JOIN 
        PostHistoryStats phs ON lp.PostId = phs.PostId
    GROUP BY 
        lp.PostId, lp.Title, lp.OwnerDisplayName, lp.PostCreationDate, lp.ViewCount, lp.AverageUpVotes, lp.CommentCount, lp.Tags
)
SELECT 
    ps.*,
    RANK() OVER (ORDER BY ps.AverageUpVotes DESC, ps.ViewCount DESC, ps.TotalEdits DESC) AS Rank
FROM 
    PostScores ps
ORDER BY 
    Rank
LIMIT 10;
