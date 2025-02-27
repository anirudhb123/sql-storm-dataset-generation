WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(v.VoteTypeId = 10) AS DeletionVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= '2020-01-01' AND u.Reputation > 1000
    GROUP BY 
        u.Id
), BadgeStats AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges
    GROUP BY 
        UserId
), CombinedStats AS (
    SELECT 
        us.UserId, 
        us.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.AcceptedAnswers,
        us.UpVotes,
        us.DownVotes,
        us.DeletionVotes,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldCount, 0) AS GoldCount,
        COALESCE(bs.SilverCount, 0) AS SilverCount,
        COALESCE(bs.BronzeCount, 0) AS BronzeCount
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeStats bs ON us.UserId = bs.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount,
    QuestionCount,
    AnswerCount,
    AcceptedAnswers,
    UpVotes,
    DownVotes,
    DeletionVotes,
    BadgeCount,
    GoldCount,
    SilverCount,
    BronzeCount
FROM 
    CombinedStats
WHERE 
    PostCount > 10
ORDER BY 
    Reputation DESC, 
    AcceptedAnswers DESC 
LIMIT 50;
