WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate > CURRENT_TIMESTAMP - INTERVAL '1 year' 
        AND u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
PostStatistics AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        a.DisplayName AS OwnerDisplayName,
        a.BadgeCount,
        cp.ClosedDate,
        cp.ClosedBy,
        cp.CloseReason,
        CASE 
            WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers a ON rp.OwnerUserId = a.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.BadgeCount,
    ps.ClosedDate,
    ps.ClosedBy,
    ps.CloseReason,
    ps.PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.PostStatus = 'Active'
ORDER BY 
    ps.ViewCount DESC
LIMIT 10;

-- Aggregate results of closed posts with their closure reasons
SELECT 
    cp.CloseReason,
    COUNT(cp.PostId) AS Count
FROM 
    ClosedPosts cp
GROUP BY 
    cp.CloseReason
ORDER BY 
    Count DESC
LIMIT 5;

This SQL query first prepares several Common Table Expressions (CTEs):
1. **RankedPosts**: Ranks the questions based on their scores.
2. **ActiveUsers**: Retrieves active users with a reputation greater than 100 and counts their badges.
3. **ClosedPosts**: Extracts details of posts that have been closed along with their closure reasons and who closed them.
4. **PostStatistics**: Combines information from the previous CTEs to produce a list of active posts along with their details.

Finally, it selects the top 10 active posts sorted by view count. Following that, it generates a summary of closed posts, counting each close reason.
