WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.Reputation,
    ur.TotalBounties,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = ur.UserId)
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    ur.Reputation DESC
LIMIT 50;

SELECT 
    'Total Uptime' AS Metric, 
    COUNT(*) AS TotalPosts
FROM 
    Posts
UNION ALL
SELECT 
    'Total Unique Users', COUNT(DISTINCT Id)
FROM 
    Users
UNION ALL
SELECT 
    'Total Comments', COUNT(*)
FROM 
    Comments;

SELECT 
    DISTINCT p.Title,
    p.CreationDate,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    Posts p
LEFT JOIN 
    Posts pa ON p.AcceptedAnswerId = pa.Id
WHERE 
    p.PostTypeId = 1 AND
    p.LastActivityDate > p.CreationDate - INTERVAL '2 months'
ORDER BY 
    p.CreationDate DESC;
