
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS tag
         FROM 
         (SELECT a.N + b.N * 10 + 1 n
          FROM 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
           SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
           SELECT 8 UNION ALL SELECT 9) a,
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
           SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
           SELECT 8 UNION ALL SELECT 9) b) n
         WHERE 
         n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')))) AS tag
        ) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount
),

VoteSummaries AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.Badges,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score AS PostScore,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Tags,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes
FROM 
    Users u
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    Posts p ON u.Id = p.OwnerUserId
JOIN 
    PostStatistics ps ON ps.PostId = p.Id
LEFT JOIN 
    VoteSummaries vs ON ps.PostId = vs.PostId
ORDER BY 
    ub.BadgeCount DESC, ps.ViewCount DESC
LIMIT 50;
