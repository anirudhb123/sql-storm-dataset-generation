WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS UsageCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    GROUP BY 
        t.Id, t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
RecentPostHistory AS (
    SELECT 
        ph.UserDisplayName,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.PostTypeId,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
)
SELECT 
    ua.DisplayName AS UserName,
    ua.Reputation,
    ua.PostCount,
    ua.TotalScore,
    GROUP_CONCAT(DISTINCT pt.TagName) AS TagsUsed,
    pt.TagName AS PopularTag,
    p.Title AS RecentPostTitle,
    rph.Comment AS RecentActionComment
FROM 
    UserActivity ua
LEFT JOIN 
    Posts p ON ua.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Posts pt ON p.Tags LIKE '%' || pt.Tags || '%'
LEFT JOIN 
    PopularTags pt ON pt.TagId IN (SELECT UNNEST(string_to_array(p.Tags, ',')))
LEFT JOIN 
    RecentPostHistory rph ON p.Id = rph.PostId
GROUP BY 
    ua.UserId, pt.TagName, p.Title, rph.Comment
HAVING 
    ua.PostCount > 10 AND
    ua.Reputation > 1000
ORDER BY 
    ua.TotalScore DESC, ua.PostCount DESC;
