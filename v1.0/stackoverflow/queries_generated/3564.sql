WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.TotalComments,
        ps.TotalUpvotes,
        ps.TotalDownvotes,
        ps.AverageBounty,
        RANK() OVER (ORDER BY ps.TotalUpvotes DESC) AS PostRank
    FROM PostStats ps
    WHERE ps.TotalUpvotes > 0
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalBadges,
    rp.Title,
    rp.TotalComments,
    rp.TotalUpvotes,
    rp.TotalDownvotes,
    rp.AverageBounty,
    CASE 
        WHEN rp.TotalUpvotes > rp.TotalDownvotes THEN 'Positive'
        ELSE 'Negative'
    END AS VoteSentiment
FROM TopUsers u
JOIN RankedPosts rp ON u.UserId = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Title = rp.Title 
    LIMIT 1
)
WHERE u.ReputationRank <= 10
ORDER BY u.Reputation DESC, rp.TotalUpvotes DESC
LIMIT 5;
