
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p 
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        CASE 
            WHEN ur.Reputation < 100 THEN 'Newbie' 
            WHEN ur.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate' 
            ELSE 'Expert' 
        END AS UserLevel
    FROM 
        RecentPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.AnswerCount,
    pm.Reputation,
    pm.UserLevel,
    COALESCE(MAX(CASE WHEN vt.Name = 'UpMod' THEN v.UserId END), -1) AS LastUpVoter,
    COALESCE(MAX(CASE WHEN vt.Name = 'DownMod' THEN v.UserId END), -1) AS LastDownVoter,
    CASE 
        WHEN pm.CommentCount > 10 THEN 'High Interaction' 
        ELSE 'Low Interaction' 
    END AS InteractionLevel
FROM 
    PostMetrics pm
LEFT JOIN 
    Votes v ON pm.PostId = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    pm.AnswerCount = (SELECT MAX(AnswerCount) FROM PostMetrics) 
    AND pm.UserLevel = 'Expert'
GROUP BY 
    pm.PostId, pm.Title, pm.Score, pm.ViewCount, pm.CommentCount, pm.AnswerCount, pm.Reputation, pm.UserLevel
ORDER BY 
    pm.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
