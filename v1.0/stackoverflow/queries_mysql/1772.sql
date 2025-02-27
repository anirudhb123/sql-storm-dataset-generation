
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PostWithUserReputation AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        ur.Reputation AS UserReputation,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    pw.UserReputation,
    pw.BadgeCount,
    SUM(CASE WHEN pw.Score > 10 THEN 1 ELSE 0 END) AS HighScoringPosts,
    GROUP_CONCAT(pw.Title) AS PostTitles
FROM 
    PostWithUserReputation pw
GROUP BY 
    pw.UserReputation, pw.BadgeCount
HAVING 
    COUNT(*) > 5
ORDER BY 
    pw.UserReputation DESC
LIMIT 10;
