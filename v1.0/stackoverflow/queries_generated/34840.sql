WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 2 -- Only Answers

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.Id = r.ParentId
),

UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(u.PostCount, 0) AS UserPostCount,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY p.Title ORDER BY p.LastActivityDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        UserPosts u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        UserBadges b ON u.UserId = b.UserId
    WHERE 
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.LastActivityDate,
    pa.UserPostCount,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    COUNT(ch.PostId) AS ChildAnswerCount,
    MAX(r.Level) AS MaxLevel
FROM 
    PostActivity pa
LEFT JOIN 
    RecursivePostHierarchy r ON pa.PostId = r.ParentId
LEFT JOIN 
    Posts ch ON pa.PostId = ch.ParentId
GROUP BY 
    pa.PostId, pa.Title, pa.CreationDate, pa.LastActivityDate, 
    pa.UserPostCount, pa.GoldBadges, pa.SilverBadges, pa.BronzeBadges
HAVING 
    COUNT(ch.PostId) > 0 OR MAX(r.Level) IS NOT NULL
ORDER BY 
    pa.TotalViews DESC, pa.LastActivityDate DESC;
