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
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
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
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ah.ParsedTags,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            STRING_AGG(DISTINCT TagName, ', ') AS ParsedTags
        FROM 
            Tags t
        JOIN 
            Posts p ON t.Id = ANY(string_to_array(p.Tags, ', ')::int[])
        GROUP BY 
            PostId
    ) ah ON p.Id = ah.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5)
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    p.Title AS PostTitle,
    p.ViewCount AS PostViews,
    p.Score AS PostScore,
    ub.DisplayName AS Author,
    ub.BadgeCount AS TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT ph.CreationDate::date, ', ') AS EditDates,
    ARRAY_AGG(DISTINCT rh.Title) AS ChildPosts
FROM 
    PostStatistics p
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    RecursivePostHierarchy rh ON p.PostId = rh.ParentId
GROUP BY 
    p.Title, p.ViewCount, p.Score, ub.DisplayName, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 50;
