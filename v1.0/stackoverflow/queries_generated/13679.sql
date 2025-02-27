-- Performance benchmarking query

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS UserBadges,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    ps.PostId, 
    ps.Title, 
    ps.PostTypeId, 
    ps.CommentCount, 
    ps.UpVotes, 
    ps.DownVotes, 
    ps.BadgeCount AS PostBadgeCount, 
    ps.AcceptedAnswer,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UserBadges,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostTypeId = 1 AND ps.PostId = us.UserId
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
