WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalUpVotes,
        UserRank
    FROM UserStats
    WHERE UserRank <= 10
),
PostLinksCount AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks
    FROM PostLinks pl
    GROUP BY pl.PostId
),
PostsWithLinks AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(plc.TotalLinks, 0) AS LinkCount,
        p.LastActivityDate,
        p.CreationDate
    FROM Posts p
    LEFT JOIN PostLinksCount plc ON p.Id = plc.PostId
    WHERE p.ViewCount > 50
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.AnswerCount,
    pl.PostId,
    pl.Title,
    pl.ViewCount,
    pl.LinkCount,
    DATEDIFF(CURRENT_TIMESTAMP, pl.LastActivityDate) AS DaysSinceLastActivity,
    DATEDIFF(CURRENT_TIMESTAMP, pl.CreationDate) AS PostAge,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM TopUsers tu
JOIN PostsWithLinks pl ON tu.UserId = pl.OwnerUserId
LEFT JOIN Posts p ON pl.PostId = p.Id
WHERE 
    pl.LinkCount > 0 
    AND (pl.ViewCount + tu.TotalUpVotes) > 100
ORDER BY tu.Reputation DESC, pl.ViewCount DESC;
