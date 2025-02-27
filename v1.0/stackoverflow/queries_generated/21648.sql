WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteAmount, 0)) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteAmount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ub.BadgeCount,
    ub.BadgeNames,
    COALESCE(rp.RecentPosts, 'No Recent Posts') AS RecentPosts,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.TotalVotes
FROM 
    UserReputation ur
LEFT JOIN 
    UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN (
    SELECT 
        STRING_AGG(CONCAT(Title, ' (', ViewCount, ' views)'), '; ') AS RecentPosts
    FROM 
        RecentPosts
    GROUP BY 
        OwnerDisplayName
) rp ON ur.DisplayName = rp.OwnerDisplayName
LEFT JOIN 
    PostActivity pa ON ur.UserId = pa.PostId
WHERE 
    ur.Reputation > 1000
    AND EXISTS (
        SELECT 1 
        FROM UserBadges ub2 
        WHERE ub2.UserId = ur.UserId 
        HAVING COUNT(CASE WHEN ub2.Class = 1 THEN 1 END) > 0  -- User has at least one Gold badge
    )
ORDER BY 
    ur.Reputation DESC, 
    pa.CommentCount DESC NULLS LAST
LIMIT 50;
