
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tagname
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 N FROM 
               (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                SELECT 8 UNION ALL SELECT 9) a,
               (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) 
        ) AS tag ON tag.tagname IS NOT NULL
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId, u.DisplayName
),

MostCommented AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
    ORDER BY 
        CommentCount DESC
),

LatestEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Text AS EditComment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),

PostMetrics AS (
    SELECT 
        m.PostId,
        m.Title,
        m.CommentCount,
        m.OwnerDisplayName,
        l.EditDate,
        l.Editor,
        l.EditComment,
        m.Tags
    FROM 
        MostCommented m
    LEFT JOIN 
        LatestEdits l ON m.PostId = l.PostId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CommentCount,
    pm.OwnerDisplayName,
    pm.EditDate,
    pm.Editor,
    pm.EditComment,
    pm.Tags
FROM 
    PostMetrics pm
ORDER BY 
    pm.CommentCount DESC,
    pm.EditDate DESC;
