WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rp ON p.ParentId = rp.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END AS IsClosed,
        RANK() OVER (ORDER BY COALESCE(p.Score, 0) DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) v ON p.Id = v.PostId
)
SELECT 
    ph.PostId,
    ph.Title AS PostTitle,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.IsClosed,
    ub.DisplayName AS UserDisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ph.Level
FROM 
    RecursivePostHierarchy ph
JOIN 
    PostStats ps ON ph.PostId = ps.PostId
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    ps.IsClosed = 0
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) > 5
ORDER BY 
    ps.Rank, ub.BadgeCount DESC, ph.Level
OPTION (RECOMPILE);
