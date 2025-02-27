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
        p.CreationDate > NOW() - INTERVAL '1 year'
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
    COALESCE(MAX(v.UserId) FILTER (WHERE vt.Name = 'UpMod'), -1) AS LastUpVoter,
    COALESCE(MAX(v.UserId) FILTER (WHERE vt.Name = 'DownMod'), -1) AS LastDownVoter,
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
LIMIT 10;

-- Additional CTE for anomalous post behavior 
WITH AnomalousPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        CASE 
            WHEN COUNT(v.Id) > 0 AND SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) > 
                (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) / 2 THEN 'Potentially Spammy' 
            ELSE 'Normal' 
        END AS BehaviorType
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title
    HAVING 
        COUNT(v.Id) > 5 -- Only consider posts with significant votes
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.VoteCount,
    ap.DownVotes,
    ap.UpVotes,
    ap.BehaviorType
FROM 
    AnomalousPosts ap
WHERE 
    ap.BehaviorType = 'Potentially Spammy'
ORDER BY 
    ap.DownVotes DESC
LIMIT 5;

-- Combining results for a final report
SELECT 
    CONCAT(pm.Title, ' (ID: ', pm.PostId, ')') AS PostDetails,
    pm.UserLevel AS AuthorLevel,
    ap.BehaviorType AS AnomalyBehavior
FROM 
    PostMetrics pm
LEFT JOIN 
    AnomalousPosts ap ON pm.PostId = ap.PostId
WHERE 
    pm.UserLevel = 'Expert'
ORDER BY 
    pm.Score DESC;
