WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedVoteData AS (
    SELECT 
        post.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts post
    LEFT JOIN 
        Votes v ON post.Id = v.PostId
    GROUP BY 
        post.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(ub.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(ub.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadgeCount, 0) AS BronzeBadges,
    r.Level AS PostLevel
FROM 
    Posts p
LEFT JOIN 
    AggregatedVoteData v ON p.Id = v.PostId
LEFT JOIN 
    UserBadgeCounts ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
WHERE 
    (v.TotalVotes > 0 OR ub.GoldBadgeCount > 0) 
    AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
ORDER BY 
    p.LastActivityDate DESC
OPTION (MAXRECURSION 50);
