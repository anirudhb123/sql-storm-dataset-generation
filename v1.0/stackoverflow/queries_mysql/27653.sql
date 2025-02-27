
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n FROM 
               (SELECT 0 as N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
               SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
               SELECT 8 UNION ALL SELECT 9) a 
               CROSS JOIN 
               (SELECT 0 as N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
               SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
               SELECT 8 UNION ALL SELECT 9) b) n ON CHAR_LENGTH(p.Tags)
         -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
        ) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
    ORDER BY 
        VoteCount DESC, 
        CommentCount DESC
    LIMIT 10
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 1 MONTH  
        AND ph.PostId IN (SELECT PostId FROM RankedPosts)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    ra.HistoryDate,
    ra.ChangeType,
    ra.UserDisplayName,
    ra.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC, 
    ra.HistoryDate DESC;
