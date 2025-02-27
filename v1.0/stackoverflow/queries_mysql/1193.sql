mysql
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        @rank := IF(@prevOwnerUserId = p.OwnerUserId, @rank + 1, 1) AS ScoreRank,
        @prevOwnerUserId := p.OwnerUserId
    FROM 
        Posts p, (SELECT @rank := 0, @prevOwnerUserId := NULL) r
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ra.QuestionCount,
    ra.CommentCount,
    q.Title AS TopQuestionTitle,
    q.Score AS TopQuestionScore
FROM 
    UserBadges ub
LEFT JOIN 
    RecentActivity ra ON ub.UserId = ra.UserId
LEFT JOIN 
    TopQuestions q ON ub.UserId = q.OwnerUserId AND q.ScoreRank = 1
WHERE 
    ub.BadgeCount > 0
ORDER BY 
    ub.BadgeCount DESC, ra.QuestionCount DESC;
