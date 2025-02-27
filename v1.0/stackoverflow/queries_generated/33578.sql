WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.ParentId, -1) AS ParentId,
        1 AS PostLevel
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        p.Id AS ParentId,
        rp.PostLevel + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2  -- Selecting Answers
),
PostAggregate AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(a.Score) AS TotalScore,
        MAX(a.CreationDate) AS LastAnswerDate,
        rp.PostLevel
    FROM 
        RecursivePostCTE rp
    LEFT JOIN 
        Posts a ON rp.PostId = a.ParentId
    GROUP BY 
        rp.PostId, rp.Title, rp.PostLevel
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 0
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.AnswerCount,
    pa.TotalScore,
    pa.LastAnswerDate,
    u.DisplayName AS TopUser,
    u.Reputation,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    PostAggregate pa
LEFT JOIN 
    TopUsers u ON pa.PostLevel = 1  -- Joining only for top questions (level 1)
WHERE 
    pa.AnswerCount > 5 
    AND pa.TotalScore > 10
ORDER BY 
    pa.LastAnswerDate DESC, pa.TotalScore DESC
LIMIT 10;
