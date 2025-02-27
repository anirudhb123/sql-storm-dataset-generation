WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
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
)
SELECT 
    p.Title AS QuestionTitle,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(badges.BadgeCount, 0) AS UserBadgeCount,
    badges.GoldBadges,
    badges.SilverBadges,
    badges.BronzeBadges,
    rph.Level AS PostLevel
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary vs ON p.Id = vs.PostId
LEFT JOIN 
    UserBadges badges ON u.Id = badges.UserId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
WHERE 
    p.PostTypeId = 1 — Questions
AND 
    p.CreationDate >= NOW() - INTERVAL '1 year' — Questions created in the last year
ORDER BY 
    TotalVotes DESC, 
    p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
