WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.PostTypeId = 1 -- Considering only Questions
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesReceived,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesReceived,
        COUNT(b.Id) AS BadgeCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE NULL END) AS CloseReopenCount,
        MIN(ph.CreationDate) AS FirstHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(us.DisplayName, 'Anonymous') AS UserName,
    us.Reputation,
    us.UpVotesReceived,
    us.DownVotesReceived,
    us.BadgeCount,
    us.CommentCount,
    ph.CloseReopenCount,
    ph.FirstHistoryDate,
    CASE 
        WHEN us.Reputation > 1000 THEN 'High Reputation'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN ph.CloseReopenCount > 0 THEN 'Yes'
        ELSE 'No'
    END AS HasBeenClosedOrReopened
FROM 
    RecentPosts rp
LEFT JOIN 
    Users us ON rp.OwnerUserId = us.Id
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank = 1 -- Top post for each user
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
