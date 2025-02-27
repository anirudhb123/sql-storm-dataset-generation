
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        UPPER(LEFT(p.Body, 100)) AS ShortBody,
        @row_num := IF(@owner_user_id = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_num := 0, @owner_user_id := NULL) AS vars
    WHERE
        p.CreationDate >= NOW() - INTERVAL 365 DAY
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalVotes,
    ua.RecentPosts,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.ShortBody,
    ps.Rank
FROM 
    UserActivity ua
LEFT JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ua.PostCount > 5 OR ps.Rank <= 3
ORDER BY 
    ua.TotalVotes DESC, ps.ViewCount DESC
LIMIT 100;
