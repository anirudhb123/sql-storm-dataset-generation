WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS ActivityRank,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND (p.Title IS NOT NULL OR p.Body IS NOT NULL)
        AND p.Score IS NOT NULL
),

ClosedPosts AS (
    SELECT DISTINCT
        ph.PostId,
        ph.CreationDate,
        cht.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cht ON ph.Comment::int = cht.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
),

BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 5
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.ActivityRank,
    rp.VoteCount,
    cp.CloseReason,
    bu.BadgeCount,
    bu.HighestBadgeClass
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    BadgedUsers bu ON rp.Author = bu.UserId
WHERE 
    rp.ActivityRank <= 5 -- Top 5 per post type
ORDER BY 
    COALESCE(rp.Score, -1) DESC, 
    COALESCE(cp.CreationDate, CURRENT_TIMESTAMP) ASC
LIMIT 100;

-- The query identifies the top 5 active posts from the last 30 days by category,
-- includes the author's badge information if they have more than 5 badges,
-- and lists the close reason where applicable, accounting for bizarre semantics
-- where a close reason may not exist even for closed posts (NULL checks).
