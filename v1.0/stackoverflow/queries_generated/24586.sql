WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 10
    GROUP BY 
        u.Id
),
TagSummaries AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.ViewCount) as TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        t.Count > 0
    GROUP BY 
        t.Id
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId IN (2, 4, 6) THEN ph.Text END, '; ') AS EditHistory,
        MAX(ph.CreationDate) AS LatestEdit
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.UpVotes,
    ua.DownVotes,
    ua.TotalComments,
    ts.TagName,
    ts.PostsCount,
    ts.TotalViews,
    p.Tags,
    phd.EditHistory,
    CASE 
        WHEN uv.UserId IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    UserActivity ua
LEFT JOIN 
    TagSummaries ts ON ts.PostsCount > 0
LEFT JOIN 
    Posts p ON p.OwnerUserId = ua.UserId
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId
LEFT JOIN 
    (SELECT UserId FROM Users WHERE LastAccessDate >= NOW() - INTERVAL '30 days') uv ON ua.UserId = uv.UserId
WHERE 
    (ua.UpVotes - ua.DownVotes) > 0
    OR ua.TotalComments > 10
ORDER BY 
    ua.TotalPosts DESC, ts.TotalViews DESC
LIMIT 100;
