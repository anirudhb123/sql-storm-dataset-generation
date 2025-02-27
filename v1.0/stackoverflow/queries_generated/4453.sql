WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.CloseReasonId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        CASE 
            WHEN b.Date IS NOT NULL THEN COUNT(b.Id) 
            ELSE 0 
        END AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Date
)
SELECT 
    rp.PostId,
    rp.Title,
    us.DisplayName AS Author,
    us.Reputation,
    us.Location,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    CASE 
        WHEN rp.CloseReasonId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN us.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus
FROM 
    RecentPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;

WITH PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    p.Body,
    COALESCE(pd.RevisionCount, 0) AS RevisionCount,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames
FROM 
    Posts p
LEFT JOIN 
    PostHistoryDetails pd ON p.Id = pd.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.Body LIKE '%SQL%'
GROUP BY 
    p.Id, pd.RevisionCount
HAVING 
    COALESCE(pd.RevisionCount, 0) > 0
ORDER BY 
    RevisionCount DESC;
