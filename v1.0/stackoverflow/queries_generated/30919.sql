WITH RecursivePostHierarchy AS (
    -- CTE to find the hierarchy of questions and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        CAST(p.Title AS VARCHAR(MAX)) AS HierarchyTitle
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.ParentId,
        CAST(rp.HierarchyTitle + ' -> ' + a.Title AS VARCHAR(MAX))
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2  -- Include only answers
),
PostVoteSummary AS (
    -- CTE to summarize votes for each post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    -- CTE to count badges for users
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
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    u.DisplayName AS Owner,
    coalesce(vs.UpVotes, 0) AS UpVotes,
    coalesce(vs.DownVotes, 0) AS DownVotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ph.HierarchyTitle
FROM 
    RecursivePostHierarchy ph
INNER JOIN 
    Users u ON ph.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary vs ON ph.PostId = vs.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000 -- Include only users with high reputation
ORDER BY 
    ph.CreationDate DESC;
