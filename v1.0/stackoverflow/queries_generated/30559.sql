WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        CAST(0 AS BIGINT) AS TotalEarnedFromBounties,
        1 AS Level
    FROM Users
    WHERE Reputation > 0

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        ur.TotalEarnedFromBounties + COALESCE(b.BountyAmount, 0),
        ur.Level + 1
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    JOIN Posts p ON v.PostId = p.Id
    LEFT JOIN (
        SELECT 
            UserId, 
            SUM(BountyAmount) AS BountyAmount 
        FROM Votes 
        WHERE VoteTypeId = 8 
        GROUP BY UserId
    ) b ON u.Id = b.UserId
    JOIN UserReputationCTE ur ON ur.Id = v.UserId
    WHERE v.VoteTypeId IN (8, 9) -- Bounty start, Bounty close
),

PostWithVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pv.VoteCount,
        p.AnswerCount,
        p.ViewCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) pv ON p.Id = pv.PostId
),

ActiveUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation
    FROM Users
    WHERE LastAccessDate >= NOW() - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.TotalEarnedFromBounties,
    u.BadgeCount,
    pwc.PostId,
    pwc.Title AS PostTitle,
    pwc.CreationDate AS PostCreationDate,
    pwc.VoteCount AS PostVoteCount,
    pwc.AnswerCount,
    pwc.ViewCount,
    u.HighestBadgeClass
FROM UserReputationCTE ur
JOIN ActiveUsers au ON ur.Id = au.Id
JOIN UserBadges u ON ur.Id = u.UserId
JOIN PostWithVoteCounts pwc ON ur.Id = pwc.PostId -- Assuming the post owner is the user in question
WHERE ur.TotalEarnedFromBounties > 0
ORDER BY ur.Reputation DESC, u.BadgeCount DESC
LIMIT 100;
