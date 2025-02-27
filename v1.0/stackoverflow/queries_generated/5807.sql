WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.CommentCount,
        ua.BadgeCount,
        ua.UpVoteCount,
        ua.DownVoteCount,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
    FROM UserActivity ua
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    ru.PostCount,
    ru.CommentCount,
    ru.BadgeCount,
    ru.UpVoteCount,
    ru.DownVoteCount
FROM RankedUsers ru
WHERE ru.ReputationRank <= 10
ORDER BY ru.Reputation DESC;
