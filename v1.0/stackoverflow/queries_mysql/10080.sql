
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT pt.Name) AS PostTypeNames,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT tag FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS tag 
        FROM Posts p CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
        UNION ALL SELECT 10) n) t) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.VoteCount,
    p.PostTypeNames,
    p.Tags,
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    u.TotalUpVotes,
    u.TotalDownVotes
FROM 
    PostStats p
JOIN 
    UserStats u ON p.OwnerUserId = u.UserId
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
