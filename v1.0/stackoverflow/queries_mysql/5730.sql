
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedVotes,
        pt.Name AS PostType,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tags_array
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 n FROM 
              (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
               UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
               UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
              (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
               UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
               UNION ALL SELECT 8 UNION ALL SELECT 9) b ) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) ) AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, pt.Name
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore,
        SUM(COALESCE(BadgeCount.BadgeCount, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) AS BadgeCount ON u.Id = BadgeCount.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.PostType,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.DeletionVotes,
    pm.AcceptedVotes,
    ue.DisplayName AS CreatorName,
    ue.PostsCreated,
    ue.BadgeScore,
    ue.TotalBadges,
    pm.Tags
FROM 
    PostMetrics pm
JOIN 
    UserEngagement ue ON pm.PostId = ue.UserId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;
