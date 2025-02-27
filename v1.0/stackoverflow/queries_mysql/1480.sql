
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(IFNULL(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.WikiCount,
        us.TotalBountyAmount,
        IFNULL(bc.GoldBadges, 0) AS GoldBadges,
        IFNULL(bc.SilverBadges, 0) AS SilverBadges,
        IFNULL(bc.BronzeBadges, 0) AS BronzeBadges,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeCounts bc ON us.UserId = bc.UserId,
        (SELECT @row_number := 0) AS rn
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount,
    TotalBountyAmount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Reputation DESC;
