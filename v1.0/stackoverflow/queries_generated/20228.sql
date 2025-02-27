WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

RecentActivity AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        c.UserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(rp.PostId, 0) AS RecentPostId,
    CASE 
        WHEN rp.PostId IS NOT NULL THEN 'Has Recent Posts' 
        ELSE 'No Recent Posts' 
    END AS PostStatus,
    urs.GoldBadges,
    urs.SilverBadges,
    urs.BronzeBadges,
    ra.CommentCount,
    ra.LastCommentDate,
    CASE 
        WHEN ra.LastCommentDate IS NULL THEN 'No Recent Comments'
        ELSE 'Active Commenter'
    END AS CommenterStatus
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON rp.UserPostRank = 1 AND rp.PostId = u.Id
LEFT JOIN 
    UserReputationSummary urs ON u.Id = urs.UserId
LEFT JOIN 
    RecentActivity ra ON u.Id = ra.UserId
WHERE 
    (u.Reputation > 100 OR EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.UserId = u.Id AND v.VoteTypeId IN (2, 3)
        HAVING COUNT(v.Id) > 5
    ))
    AND (rp.PostId IS NOT NULL OR ra.CommentCount > 0)
ORDER BY 
    u.Reputation DESC, 
    ra.LastCommentDate DESC NULLS LAST;
