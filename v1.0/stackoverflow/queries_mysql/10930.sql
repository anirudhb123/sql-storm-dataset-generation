
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT g.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(g.Tags, ',', numbers.n), ',', -1) AS TagName
         FROM Posts g
         INNER JOIN 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
              UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(g.Tags) - CHAR_LENGTH(REPLACE(g.Tags, ',', '')) >= numbers.n - 1) t 
    ON p.Id = t.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
VoteStats AS (
    SELECT 
        vt.Id AS VoteTypeId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS Count
    FROM 
        VoteTypes vt
    LEFT JOIN 
        Votes v ON vt.Id = v.VoteTypeId
    GROUP BY 
        vt.Id, vt.Name
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    vs.VoteTypeId,
    vs.VoteType,
    vs.Count AS VoteTypeCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = us.UserId 
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.VoteTypeId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
