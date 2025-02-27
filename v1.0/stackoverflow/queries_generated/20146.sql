WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) as UpVotesCount, -- UpMod
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) as DownVotesCount  -- DownMod
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS LastCloseDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswersCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.RecentPostRank,
    COALESCE(cr.CloseReason, 'Not Closed') AS PostCloseReason,
    COALESCE(cr.LastCloseDate, 'No Closure Date') AS LastClosureDate,
    ur.Reputation AS UserReputation,
    ur.AcceptedAnswersCount,
    ur.GoldBadges,
    p.CommentCount,
    p.UpVotesCount,
    p.DownVotesCount,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus,
    NULLIF((p.UpVotesCount - p.DownVotesCount), 0) AS VoteBalance
FROM 
    RankedPosts p
LEFT JOIN 
    CloseReasons cr ON p.PostId = cr.PostId
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
INNER JOIN 
    UserReputation ur ON ur.UserId = u.Id
WHERE 
    p.RecentPostRank = 1; -- Most recent post per user

Explanation:
- This SQL query includes the use of Common Table Expressions (CTEs) to rank posts, derive close reasons, and calculate user reputation metrics.
- It employs window functions to rank posts by their creation date per user, and to aggregate vote counts.
- The query incorporates a FILTER clause with aggregated columns and handles various cases for closed posts.
- The final SELECT retrieves attributes from all CTEs, implements NULL handling with COALESCE, and manages activity classification.
- Unusual semantics such as NULLIF are used to calculate vote balances explicitly.
