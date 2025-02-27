WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.PostTypeId,
        a.Score,
        a.CreationDate,
        a.OwnerUserId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteStats AS (
    SELECT 
        p.Id,
        p.Score,
        COUNT(v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score AS QuestionScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN pvs.Score > 0 THEN 'Positive'
        WHEN pvs.Score < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS PostSentiment,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(DISTINCT tl.RelatedPostId)
     FROM PostLinks tl 
     WHERE tl.PostId = rp.PostId AND tl.LinkTypeId = 3) AS DuplicateCount,
    MAX(rp.Level) OVER () AS MaxLevel -- Maximum level of nested posts
FROM 
    RecursivePostCTE rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.Id
WHERE 
    rp.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    rp.Score DESC, 
    PostSentiment DESC;
