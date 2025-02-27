WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        AVG(u.Reputation) AS AvgUserReputation,
        ARRAY_AGG(DISTINCT bp.UserId) AS BadgeHolders,
        STRING_AGG(DISTINCT tp.Name, ', ') AS PostTypes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges bp ON bp.UserId = p.OwnerUserId
    LEFT JOIN 
        PostTypes tp ON p.PostTypeId = tp.Id
    GROUP BY 
        t.TagName
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
    ORDER BY 
        ph.CreationDate DESC
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.AvgUserReputation,
    ARRAY_LENGTH(ts.BadgeHolders, 1) AS BadgeHolderCount,
    ts.PostTypes,
    ra.UserDisplayName AS RecentEditor,
    ra.Comment AS RecentEditComment,
    ra.CreationDate AS RecentEditDate,
    ua.DisplayName AS ActiveUser,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalBounty
FROM 
    TagStatistics ts
LEFT JOIN 
    RecentPostHistory ra ON ra.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
LEFT JOIN 
    UserActivity ua ON ua.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    ts.PostCount DESC, ua.TotalPosts DESC, ra.CreationDate DESC;
