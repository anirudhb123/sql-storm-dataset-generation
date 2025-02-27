WITH RECURSIVE UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.UpVotes AS TotalUpVotes,
        u.DownVotes AS TotalDownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Id IS NOT NULL

    UNION ALL

    SELECT 
        u.Id,
        u.UpVotes,
        u.DownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        us.Level + 1
    FROM 
        Users u
    INNER JOIN UserScore us ON u.Reputation >= us.NetVotes
    WHERE 
        us.Level < 10 -- just to limit recursion for performance
)

, PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(c.TotalComments, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalComments
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)

, PostsRanking AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.CommentCount DESC) AS CommentRank
    FROM 
        PostWithComments p
)

SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.ViewCount,
    p.CommentCount,
    pr.ViewRank,
    pr.CommentRank,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN b.BadgeCount > 0 THEN 'Has Badge'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    Users u
JOIN 
    UserScore us ON u.Id = us.UserId
JOIN 
    PostsRanking pr ON pr.CommentCount > 0
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    us.NetVotes DESC, 
    u.Reputation DESC
LIMIT 100;

This SQL script includes recursive common table expressions (CTEs) to compute user scores, a join with posts and their related comments to gather performance metrics, and ranking based on view and comment counts. Additionally, it includes badge tracking with filtering for users with a reputation above 1000. The final selection pulls various user and post metrics while incorporating conditional badge status in the results.
