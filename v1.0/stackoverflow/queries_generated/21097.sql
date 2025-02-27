WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        ph.UserId AS EditorId,
        ph.PostHistoryTypeId,
        PNT.Name AS PostNoticeType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        PostHistoryTypes PNT ON ph.PostHistoryTypeId = PNT.Id
    WHERE 
        ph.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, ph.UserId, ph.PostHistoryTypeId, PNT.Name
)
SELECT 
    up.DisplayName,
    up.Reputation,
    ua.UserRank,
    rp.Title AS RecentPostTitle,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ra.LastEditDate,
    ra.EditorId,
    ra.PostNoticeType,
    CASE 
        WHEN ra.PostHistoryTypeId IS NOT NULL AND rp.UpVotes > rp.DownVotes THEN 'Popular Edit'
        ELSE 'Unpopular Edit'
    END AS EditPopularity
FROM 
    RankedPosts rp
JOIN 
    UserStats ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    ua.UserRank <= 100
ORDER BY 
    up.Reputation DESC, rp.CommentCount DESC;
