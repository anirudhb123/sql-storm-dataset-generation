WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(COALESCE(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END, 0)) AS ClosedCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        t.TagName
),
BadgesCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        bc.BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        BadgesCount bc ON u.Id = bc.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName, bc.BadgeCount
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.QuestionsAsked,
    ua.TotalViews,
    ts.TagName,
    ts.PostCount,
    ts.AverageScore,
    ts.ClosedCount,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 0
LEFT JOIN 
    RankedPosts rp ON rp.OwnerDisplayName = ua.DisplayName AND rp.rn = 1
ORDER BY 
    ua.TotalViews DESC, ua.QuestionsAsked DESC, ts.PostCount DESC;
