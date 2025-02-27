WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank 
    FROM 
        UserStats
),
RecentPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS RecentPostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.PostCount,
        tu.QuestionCount,
        tu.AnswerCount,
        rp.RecentPostCount,
        rp.LastPostDate
    FROM 
        TopUsers tu
    LEFT JOIN 
        RecentPostStats rp ON tu.UserId = rp.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    COALESCE(cs.PostCount, 0) AS TotalPosts,
    COALESCE(cs.QuestionCount, 0) AS TotalQuestions,
    COALESCE(cs.AnswerCount, 0) AS TotalAnswers,
    COALESCE(cs.RecentPostCount, 0) AS PostsLast30Days,
    COALESCE(EXTRACT(EPOCH FROM cs.LastPostDate), 0) AS LastPostTimestamp,
    CASE 
        WHEN cs.ReputationRank IS NOT NULL THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    CombinedStats cs
WHERE 
    COALESCE(cs.PostCount, 0) > 10
ORDER BY 
    cs.Reputation DESC, cs.PostCount DESC;
