WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
UserBadgeStatistics AS (
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
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ph.Title AS QuestionTitle,
    ph.Id AS QuestionId,
    ph.ParentId AS AnswerId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COALESCE(bs.BadgeCount, 0) AS TotalBadges,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    ps.UpVotes,
    ps.DownVotes,
    ph.Level
FROM 
    RecursivePostHierarchy ph
JOIN 
    Users u ON ph.ParentId = u.Id
LEFT JOIN 
    UserBadgeStatistics bs ON u.Id = bs.UserId
LEFT JOIN 
    PostVoteStatistics ps ON ph.Id = ps.PostId
WHERE 
    (ps.UpVotes - ps.DownVotes) > 0  -- Only questions with a positive score
    AND ph.Level <= 5  -- Limiting to a maximum of 5 levels deep
ORDER BY 
    ph.Level, ps.UpVotes DESC;
