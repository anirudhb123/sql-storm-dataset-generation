WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- only fetching Close and Reopen actions
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON rph.PostId = ph.PostId
    WHERE 
        ph.CreationDate < rph.CreationDate
)
, PostWithStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score, -- Upvotes minus Downvotes
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        p.Id
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.ViewCount,
    pw.Score,
    pw.CommentCount,
    pw.BadgeCount,
    rph.UserDisplayName AS LastActionBy,
    MAX(rph.CreationDate) AS LastActionDate,
    CASE 
        WHEN COUNT(DISTINCT rph.PostHistoryTypeId) > 1 THEN 'Closed and Reopened'
        WHEN COUNT(DISTINCT rph.PostHistoryTypeId) = 1 AND MIN(rph.PostHistoryTypeId) = 10 THEN 'Closed'
        WHEN COUNT(DISTINCT rph.PostHistoryTypeId) = 1 AND MIN(rph.PostHistoryTypeId) = 11 THEN 'Reopened'
        ELSE 'No Actions'
    END AS PostStatus
FROM 
    PostWithStatistics pw
LEFT JOIN 
    RecursivePostHistory rph ON pw.PostId = rph.PostId
GROUP BY 
    pw.PostId, pw.Title, pw.ViewCount, pw.Score, pw.CommentCount, pw.BadgeCount, rph.UserDisplayName
ORDER BY 
    pw.Score DESC, pw.ViewCount DESC;
