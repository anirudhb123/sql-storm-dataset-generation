WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10)
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.LastPostDate,
    pt.TagName,
    pt.TotalViews,
    pt.PostCount,
    rph.EditCount,
    rph.LastEditDate
FROM 
    UserActivity ua
JOIN 
    PopularTags pt ON ua.TotalPosts > 0
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
ORDER BY 
    ua.Reputation DESC, pt.TotalViews DESC;
