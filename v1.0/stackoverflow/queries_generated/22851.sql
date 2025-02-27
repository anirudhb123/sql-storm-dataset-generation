WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(SUM(vote.BountyAmount), 0) AS TotalBounty,
        COUNT(cv.Id) AS CloseVoteCount,
        SUM(v.CreationDate > p.CreationDate) AS NewVotesCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)  -- Bounty Start and Bounty Close
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN Votes cv ON cv.PostId = p.Id AND cv.VoteTypeId = 6 -- Close votes
    WHERE p.CreationDate > NOW() - INTERVAL '30 days' 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate
),
FilteredBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    JOIN Users u ON u.Id = b.UserId
    WHERE u.Reputation > 500  -- Users with more than 500 reputation
    GROUP BY u.Id, b.Name
),
PostLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM PostLinks pl
    GROUP BY pl.PostId
),
UserReputationRanks AS (
    SELECT 
        u.Id,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
)
SELECT 
    p.Title,
    p.ViewCount,
    r.TotalBounty,
    COALESCE(plc.RelatedPostCount, 0) AS RelatedPosts,
    CASE 
        WHEN ra.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN ra.ReputationRank <= 50 THEN 'Frequent Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel,
    STRING_AGG(DISTINCT fb.Name, ', ') AS BadgeList
FROM RecentPostActivity r
JOIN Posts p ON p.Id = r.PostId
LEFT JOIN PostLinkCounts plc ON plc.PostId = r.PostId
JOIN UserReputationRanks ra ON ra.Id = p.OwnerUserId
LEFT JOIN FilteredBadges fb ON fb.UserId = p.OwnerUserId
WHERE r.rn = 1 -- Just take the latest post from each user
GROUP BY p.Title, p.ViewCount, r.TotalBounty, plc.RelatedPostCount, ra.ReputationRank
HAVING SUM(r.CloseVoteCount) = 0 -- Exclude posts that are closed
ORDER BY r.TotalBounty DESC, p.ViewCount DESC;
