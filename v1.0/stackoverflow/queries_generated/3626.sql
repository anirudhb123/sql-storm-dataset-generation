WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserStats
),

HighScorers AS (
    SELECT 
        t.DisplayName,
        t.Reputation,
        t.PostCount,
        t.QuestionCount,
        t.AnswerCount,
        t.AcceptedAnswerCount,
        t.LastPostDate
    FROM 
        TopUsers t
    WHERE 
        t.ReputationRank <= 10 OR t.PostRank <= 10
)

SELECT 
    u.DisplayName,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.AcceptedAnswerCount,
    CASE 
        WHEN u.LastPostDate IS NULL THEN 'Never posted'
        ELSE to_char(u.LastPostDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastPostFormatted
FROM 
    HighScorers u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId AND b.Class = 1
WHERE 
    u.AnswerCount > 0 
ORDER BY 
    u.Reputation DESC, u.LastPostDate DESC 
LIMIT 20;

SELECT 
    DISTINCT t.FirstTag, 
    COUNT(DISTINCT p.Id) AS PostCount
FROM 
    (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS FirstTag
        FROM 
            Posts
        WHERE 
            Tags IS NOT NULL
    ) AS t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.FirstTag || '%'
GROUP BY 
    t.FirstTag
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    PostCount DESC;
