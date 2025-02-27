
WITH CTE_PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        COALESCE(MAX(v.CreationDate), p.CreationDate) AS LastVoteDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.LastVoteDate
    FROM 
        CTE_PostStats ps
    WHERE 
        ps.CommentCount > 5
        OR ps.UpVoteCount - ps.DownVoteCount > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class AS BadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Name, b.Class
)
SELECT 
    u.DisplayName,
    fp.Title,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    ub.BadgeName,
    ub.BadgeClass,
    ub.BadgeCount,
    CASE 
        WHEN fp.LastVoteDate IS NULL THEN 'No votes yet' 
        WHEN fp.LastVoteDate < '2024-10-01 12:34:56' - INTERVAL 30 DAY THEN 'Old Vote Activity'
        ELSE 'Recent Vote Activity'
    END AS VoteActivityStatus,
    GROUP_CONCAT(DISTINCT tg.TagName ORDER BY tg.TagName SEPARATOR ', ') AS Tags
FROM 
    FilteredPosts fp
    JOIN Users u ON fp.PostId = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN (
        SELECT DISTINCT 
            p.Id AS PostId, 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS TagName
        FROM 
            Posts p
        JOIN 
            (SELECT a.N + b.N * 10 AS n FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
        WHERE 
            n.n < 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', ''))
    ) tg ON fp.PostId = tg.PostId
GROUP BY 
    u.DisplayName, fp.Title, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount, ub.BadgeName, ub.BadgeClass, ub.BadgeCount, fp.LastVoteDate
HAVING 
    COUNT(DISTINCT tg.TagName) BETWEEN 1 AND 5
ORDER BY 
    fp.LastVoteDate DESC, 
    u.DisplayName;
