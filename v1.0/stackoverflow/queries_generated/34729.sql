WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of posts
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CreationDate,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteSummary AS (
    -- Summarizing votes per post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    -- Aggregate user badges
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    pp.Id AS PostId,
    pp.Title,
    pp.CreationDate,
    pp.Level,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    u.DisplayName AS OwnerName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(ARRAY_AGG(DISTINCT c.UserDisplayName) FILTER (WHERE c.Id IS NOT NULL), '{}') AS Commenters,
    COUNT(c.Id) AS CommentCount
FROM 
    RecursivePostHierarchy pp
LEFT JOIN 
    PostVoteSummary pvs ON pp.Id = pvs.PostId
JOIN 
    Users u ON pp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    Comments c ON c.PostId = pp.Id
GROUP BY 
    pp.Id, pp.Title, pp.CreationDate, pp.Level, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    pp.Level DESC, pp.CreationDate DESC;
