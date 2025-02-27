WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000 -- Only consider users with a reputation above 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        UserRank
    FROM UserActivity
    WHERE UserRank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY p.Id
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.AnswerStatus,
    ps.CommentCount,
    ps.CloseCount
FROM TopUsers tu
JOIN PostStats ps ON tu.UserId = ps.PostId
ORDER BY tu.UserRank, ps.CreationDate DESC;
