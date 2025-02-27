WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserBagdesAndReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(u.Reputation) AS MaxReputation,
        COUNT(*) AS BadgeCount
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
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostsWithTags AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(ps.TotalVotes, 0) AS TotalVotes,
    ubr.UserId,
    ubr.GoldBadges,
    ubr.SilverBadges,
    ubr.BronzeBadges,
    ubr.MaxReputation,
    pwt.Tags,
    rph.Level
FROM 
    Posts p
LEFT JOIN 
    PostVoteStatistics ps ON ps.PostId = p.Id
JOIN 
    UserBagdesAndReputation ubr ON ubr.UserId = p.OwnerUserId
LEFT JOIN 
    PostsWithTags pwt ON pwt.Id = p.Id
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.Id = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    p.CreationDate DESC,
    p.Score DESC;
