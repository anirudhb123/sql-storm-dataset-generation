WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Select root posts (questions)
    
    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVotes AS (
    SELECT 
        postId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        postId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COALESCE(v.UpVotes, 0) AS UpVoteCount,
    COALESCE(v.DownVotes, 0) AS DownVoteCount,
    u.DisplayName AS OwnerName,
    b.TotalBadges AS UserTotalBadges,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges,
    RANK() OVER (PARTITION BY r.Level ORDER BY p.CreationDate DESC) AS RankWithinLevel,
    COUNT(c.Id) AS CommentCount,
    NULLIF(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS CloseCount
FROM 
    Posts p
LEFT JOIN 
    PostVotes v ON p.Id = v.postId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
WHERE 
    p.CreationDate > DATEADD(YEAR, -1, GETDATE())  -- Last 1 year posts
GROUP BY 
    p.Id, p.Title, p.CreationDate, v.UpVotes, v.DownVotes, u.DisplayName, b.TotalBadges, b.GoldBadges, b.SilverBadges, b.BronzeBadges, r.Level
ORDER BY 
    r.Level, RankWithinLevel;
