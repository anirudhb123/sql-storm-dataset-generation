
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(v.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPosts
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
        ISNULL(c.CommentCount, 0) AS CommentCount,
        UPPER(SUBSTRING(p.Body, 1, 100)) AS ShortBody,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
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
    WHERE
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '365 days'
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
FULL OUTER JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ua.PostCount > 5 OR ps.Rank <= 3
ORDER BY 
    ua.TotalVotes DESC, ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
