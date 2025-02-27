WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rc.CommentCount,
    rc.LastCommentDate
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentComments rc ON rp.Id = rc.PostId
WHERE 
    up.Reputation > 100 AND 
    rp.PostRank = 1
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 10;

WITH TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
)

SELECT 
    tu.TagName,
    tu.UsageCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TagUsage tu
LEFT JOIN (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  -- Gold badges
    GROUP BY 
        b.UserId
) AS b ON b.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Tags LIKE '%' || tu.TagName || '%')
ORDER BY 
    tu.UsageCount DESC;
