WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS TotalComments,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT crt.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::jsonb->>'closeReasonTypeId'::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.PostCount,
    ua.CommentCount,
    ua.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.TotalComments,
    ps.AvgViewCount,
    COALESCE(cr.CloseReasonNames, '{}') AS CloseReasons
FROM 
    UserActivity ua
JOIN 
    PostStats ps ON ua.UserId = ps.PostId
LEFT JOIN 
    CloseReasons cr ON ps.PostId = cr.PostId
WHERE 
    ua.PostCount > 5 AND 
    ua.UpVotes > ua.DownVotes
ORDER BY 
    ua.UpVotes DESC,
    ps.Score DESC;
