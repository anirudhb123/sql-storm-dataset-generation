
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    ISNULL(bs.BadgeCount, 0) AS BadgeCount,
    ISNULL(bs.GoldBadges, 0) AS GoldBadges,
    ISNULL(bs.SilverBadges, 0) AS SilverBadges,
    ISNULL(bs.BronzeBadges, 0) AS BronzeBadges,
    ISNULL(ps.TotalPosts, 0) AS TotalPosts,
    ISNULL(ps.AverageScore, 0) AS AverageScore,
    ISNULL(ps.TotalViews, 0) AS TotalViews,
    ISNULL(ps.UniqueTags, 0) AS UniqueTags
FROM 
    UserStats us
LEFT JOIN 
    BadgeStats bs ON us.UserId = bs.UserId
LEFT JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.PostCount DESC, us.UpVotes DESC;
