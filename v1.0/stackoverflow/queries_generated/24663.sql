WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    p.PostId,
    p.Title,
    u.DisplayName AS Owner,
    us.Reputation,
    us.BadgeCount,
    phc.EditCount,
    phc.CloseCount,
    phc.DeleteCount,
    RANK() OVER (ORDER BY (us.Reputation + 10 * us.BadgeCount) DESC) AS UserRank
FROM 
    RankedPosts p
JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
JOIN 
    PostHistoryCounts phc ON p.PostId = phc.PostId
WHERE 
    phc.CloseCount = 0  -- Excluding closed posts
    AND (p.UpVotes - p.DownVotes) > 10  -- Excluding underperforming posts
ORDER BY 
    UserRank,
    p.CreationDate DESC
LIMIT 50;

This query achieves several objectives:
1. It calculates statistics about posts created in the last 30 days, including user reputation and badge counts.
2. It includes outer joins to collect votes and badge information, demonstrating the use of COALESCE for null handling.
3. A Common Table Expression (CTE) is used several times for clarity and organization of the query.
4. It incorporates window functions with `DENSE_RANK()` and `RANK()`, showing how user ranking can be influenced by votes and badges.
5. The use of complicated predicates to filter out closed and low-performing posts creates a tailored dataset for performance benchmarking.
