WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '1 year')
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        cp.LastClosedDate,
        us.TotalBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    pws.PostId,
    pws.Title,
    pws.CreationDate,
    pws.Score,
    pws.ViewCount,
    pws.AnswerCount,
    pws.CloseCount,
    CASE 
        WHEN pws.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CONCAT(us.DisplayName, ' (', us.Reputation, ' - ', us.TotalBadges, ' badges)') AS OwnerInfo
FROM 
    PostsWithStats pws
JOIN 
    Users us ON pws.OwnerUserId = us.Id
WHERE 
    pws.Rank <= 5  -- Limit to five most recent posts per user
ORDER BY 
    pws.CreationDate DESC
LIMIT 50;
