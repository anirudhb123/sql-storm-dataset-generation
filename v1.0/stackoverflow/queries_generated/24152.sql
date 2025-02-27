WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        CONCAT(u.Location, ' (', u.Reputation, ')') AS UserLocationAndReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP) 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.UserLocationAndReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 1 AND rp.rn <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate IS NOT NULL 
    GROUP BY 
        p.Id
)
SELECT 
    tq.Title,
    tq.Score,
    tq.ViewCount,
    tq.OwnerDisplayName,
    tq.UserLocationAndReputation,
    u.BadgeCount,
    u.BadgeNames,
    phs.EditCount,
    phs.LastEditDate,
    phs.HistoryTypes
FROM 
    TopQuestions tq
JOIN 
    UserBadges u ON tq.OwnerUserId = u.UserId
JOIN 
    PostHistorySummary phs ON tq.Id = phs.PostId
WHERE 
    (u.BadgeCount > 0 OR u.BadgeCount IS NULL) 
    AND tq.ViewCount > 100
ORDER BY 
    tq.Score DESC, tq.CreationDate ASC;

-- Additional Performance Benchmarking Example
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AvgBountyAmount,
    CASE 
        WHEN COUNT(v.Id) = 0 THEN 'No Votes'
        WHEN COUNT(v.Id) > 10 THEN 'Highly Voted'
        ELSE 'Moderately Voted'
    END AS VoteDescription,
    RANK() OVER (ORDER BY AVG(v.BountyAmount) DESC) AS VoteRank
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(month, -6, CURRENT_TIMESTAMP)
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(v.Id) > 5;

-- Closing notes about Bizarre SQL Semantics
WITH RecursiveCTE AS (
    SELECT 
        1 AS n
    UNION ALL
    SELECT 
        n + 1 
    FROM 
        RecursiveCTE
    WHERE 
        n < 5
)
SELECT 
    n,
    CASE 
        WHEN n % 2 = 0 THEN 'Even'
        ELSE 'Odd'
    END AS OddOrEven
FROM 
    RecursiveCTE;
