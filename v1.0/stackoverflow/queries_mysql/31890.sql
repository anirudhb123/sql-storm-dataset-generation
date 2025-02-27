
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),

UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ph.Level,
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ud.UpVotes,
        ud.DownVotes,
        ud.BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserDetails ud ON u.Id = ud.UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.Level,
    ps.DisplayName AS OwnerDisplayName,
    ps.Reputation,
    ps.UpVotes - ps.DownVotes AS NetVotes,
    CASE 
        WHEN ps.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    PostStats ps
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.TAGS, '<>', n.n), '<>', -1) AS TagName, p.Id 
     FROM Posts p 
     JOIN (SELECT a.N FROM (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                           UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a 
            CROSS JOIN (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) b 
            ) n ON CHAR_LENGTH(p.TAGS) - CHAR_LENGTH(REPLACE(p.TAGS, '<>', '')) >= n.n-1
    ) AS t ON ps.PostId = t.Id
GROUP BY 
    ps.PostId, ps.Title, ps.ViewCount, ps.Score, ps.Level, ps.DisplayName, ps.Reputation, ps.UpVotes, ps.DownVotes, ps.BadgeCount
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
