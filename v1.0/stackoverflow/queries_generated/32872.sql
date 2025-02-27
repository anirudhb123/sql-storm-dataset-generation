WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)   -- Only Questions and Answers
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreated
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    e.UpVotes,
    e.DownVotes,
    e.CommentCount,
    CASE
        WHEN pp.Score > 10 AND pp.ViewCount > 1000 THEN 'High Engagement'
        WHEN pp.Score > 5 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RecursivePostCTE pp
JOIN 
    Posts p ON pp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    PostEngagement e ON p.Id = e.PostId
WHERE 
    pp.RN <= 5  -- Get top 5 recent Questions and Answers
    AND ur.Reputation >= 100  -- Only include users with reputation
ORDER BY 
    pp.CreationDate DESC;
