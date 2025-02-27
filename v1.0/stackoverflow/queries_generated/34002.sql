WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Depth
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        Depth + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- Only Bounty start and close
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostsCount,
        BadgesCount,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
    WHERE Reputation > 1000  -- Filter for high reputation users
),
PostActivities AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ph.Comment, 'No comment') AS EditComment,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body and Tag edits
)
SELECT 
    p.PostId,
    p.Title AS PostTitle,
    p.Score,
    p.ViewCount,
    r.Depth AS QuestionDepth,
    t.UserId AS TopUserId,
    t.Reputation AS UserReputation,
    t.PostsCount AS UserPostsCount,
    t.BadgesCount AS UserBadgesCount,
    t.TotalBounties AS UserTotalBounties,
    p.EditComment,
    p.EditDate
FROM RecursivePostCTE r
JOIN Posts qp ON r.PostId = qp.Id
JOIN PostActivities p ON p.PostId = qp.AcceptedAnswerId -- Joining with accepted answers if any
LEFT JOIN TopUsers t ON qp.OwnerUserId = t.UserId
WHERE qp.Score > 10 -- Filter for highly scored questions
ORDER BY p.EditDate DESC, t.Reputation DESC
LIMIT 100; -- Limit for performance testing
