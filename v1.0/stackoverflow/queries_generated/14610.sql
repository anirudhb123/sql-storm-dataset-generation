-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        DATEDIFF(CURRENT_TIMESTAMP, p.CreationDate) AS PostAgeInDays
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        AVG(ps.PostAgeInDays) AS AveragePostAge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalPostViews,
    us.TotalAnswers,
    us.AveragePostAge,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.PostAgeInDays
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.TotalPostViews DESC, ps.VoteCount DESC;
