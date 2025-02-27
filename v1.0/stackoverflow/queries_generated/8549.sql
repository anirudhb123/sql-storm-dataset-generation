WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        AVG(COALESCE((
            SELECT 
                COALESCE(AVG(vote.Score), 0) 
            FROM Votes vote 
            WHERE vote.PostId IN (SELECT p2.Id FROM Posts p2 WHERE p2.OwnerUserId = u.Id)
        ), 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostInteractions AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.DisplayName,
        us.Reputation,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.TotalViews,
        us.BadgeCount,
        us.AvgPostScore,
        pi.CommentCount,
        pi.EditCount
    FROM 
        UserStats us
    JOIN 
        PostInteractions pi ON us.UserId = pi.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    BadgeCount,
    AvgPostScore,
    CommentCount,
    EditCount
FROM 
    CombinedStats
WHERE 
    Reputation > 1000
ORDER BY 
    Reputation DESC, PostCount DESC
LIMIT 50;
