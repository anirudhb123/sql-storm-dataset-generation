
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        @rank := IF(@prevLastActivityDate = p.LastActivityDate, @rank, @rank + 1) AS PostRank,
        @prevLastActivityDate := p.LastActivityDate
    FROM 
        Posts p, 
        (SELECT @rank := 0, @prevLastActivityDate := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        p.LastActivityDate DESC
), RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pr.PostId,
    pr.Title,
    pr.PostRank,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    rc.LastCommentDate
FROM 
    UserStats us
JOIN 
    PostRankings pr ON pr.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        JOIN Users u ON p.OwnerUserId = u.Id
        WHERE u.Id = us.UserId
    )
LEFT JOIN 
    RecentComments rc ON pr.PostId = rc.PostId
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalPosts DESC, pr.PostRank ASC
LIMIT 10;
