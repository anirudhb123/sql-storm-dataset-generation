
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.FavoriteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(tag) AS tag FROM (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.Number), ',', -1) AS tag
            FROM Posts p
            JOIN (
                SELECT a.N + b.N * 10 + 1 AS Number
                FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                     (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                ) numbers
            WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.Number - 1
        ) AS temp) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.FavoriteCount, p.OwnerUserId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Tags,
    us.UserId,
    us.DisplayName AS AuthorDisplayName,
    us.PostsCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    bs.BadgeCount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    BadgeStats bs ON u.Id = bs.UserId
ORDER BY 
    ps.Score DESC;
