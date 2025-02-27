WITH RecursivePostCTE AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        Score,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserBadgeStats AS (
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
PostHistoryAnalytics AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)

SELECT 
    p.Title,
    p.CreationDate,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    COALESCE(pb.ClosedDate, pb.ReopenedDate) AS RecentClosedStatusDate,
    ub.BadgeCount AS TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COUNT(r.PostId) AS AnswerCount,
    STUFF((SELECT ',' + r2.Title 
           FROM RecursivePostCTE r2 
           WHERE r2.ParentId = p.Id 
           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS AnswerTitles
FROM 
    Posts p
LEFT JOIN 
    PostVoteSummary ps ON p.Id = ps.PostId
LEFT JOIN 
    PostHistoryAnalytics pb ON p.Id = pb.PostId
LEFT JOIN 
    UserBadgeStats ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.ParentId
WHERE 
    p.PostTypeId = 1 -- Filtering for questions only
    AND p.CreationDate >= DATEADD(DAY, -30, GETDATE()) -- Only the last 30 days
GROUP BY 
    p.Title, p.CreationDate, ps.UpVotes, ps.DownVotes, ps.TotalVotes, 
    pb.ClosedDate, pb.ReopenedDate, ub.BadgeCount, ub.GoldBadges, 
    ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    p.CreationDate DESC;
