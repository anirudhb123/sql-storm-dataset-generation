WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.ViewCount > 10 AND 
        p.Score BETWEEN 1 AND 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (1, 4) THEN ph.CreationDate END) AS LastTitleChange,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (2, 5) THEN ph.CreationDate END) AS LastBodyChange
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalBadges,
    ua.TotalComments,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ph.LastTitleChange,
    ph.LastBodyChange,
    (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent Post'
        ELSE 'Other Posts' 
    END AS PostType
FROM 
    UserActivity ua
JOIN 
    Users u ON ua.UserId = u.Id
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistoryStats ph ON rp.PostId = ph.PostId
WHERE 
    rp.Score > (
        SELECT 
            AVG(Score) 
        FROM 
            Posts 
        WHERE 
            ViewCount > 10
    )
ORDER BY 
    u.Reputation DESC, 
    rp.Score DESC;
