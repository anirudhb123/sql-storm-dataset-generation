WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(COALESCE(v.VoteTypeId IN (2, 3), 0)) AS VoteCount,
        SUM(COALESCE(b.Class = 1, 0)) AS GoldBadgeCount,
        SUM(COALESCE(b.Class = 2, 0)) AS SilverBadgeCount,
        SUM(COALESCE(b.Class = 3, 0)) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        AcceptedAnswerCount,
        VoteCount,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    AnswerCount,
    AcceptedAnswerCount,
    VoteCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
