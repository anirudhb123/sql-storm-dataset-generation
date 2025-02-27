WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.AnswerCount,
    us.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Tags
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerDisplayName
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.PostCount DESC, rp.CreationDate DESC;
