WITH RecursivePostHistory AS (
    SELECT 
        Id,
        PostId,
        PostHistoryTypeId,
        CreationDate,
        UserId,
        Comment,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM 
        PostHistory
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
                WHEN b.Class = 1 THEN 3
                WHEN b.Class = 2 THEN 2
                WHEN b.Class = 3 THEN 1
                ELSE 0
            END) AS BadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.Score) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
)
SELECT 
    rph.PostId,
    rp.Title,
    rp.CreationDate AS PostDate,
    u.Reputation,
    u.BadgeCount,
    u.BadgePoints,
    rph.Comment,
    rp.AverageScore,
    COALESCE(rph.Comment, 'No Comments') AS LatestComment
FROM 
    RecursivePostHistory rph
JOIN 
    RecentPosts rp ON rph.PostId = rp.PostId
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
WHERE 
    rph.rn = 1
AND 
    (
        u.Reputation > 1000 
        OR EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.UserId AND b.Class = 1)
    )
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;

-- Additional performance benchmarking metrics can be added as needed
