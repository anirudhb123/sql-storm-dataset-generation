WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS AcceptedAnswersCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
), CommentsCount AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ab.AcceptedAnswersCount, 0) AS TotalAcceptedAnswers,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(rp.Title, 'No Questions') AS TopQuestionTitle,
    COALESCE(rp.Score, 0) AS TopQuestionScore,
    COALESCE(rp.ViewCount, 0) AS TopQuestionViews
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    AcceptedAnswers ab ON u.Id = ab.OwnerUserId
LEFT JOIN 
    CommentsCount cc ON u.Id = cc.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RN = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
LIMIT 10;
