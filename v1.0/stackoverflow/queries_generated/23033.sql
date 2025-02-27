WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '60 days'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS PostCount,
        SUM(CASE WHEN rp.Score IS NOT NULL THEN rp.Score ELSE 0 END) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        MAX(rp.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    AND 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TagAnalytics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    u.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.AvgViewCount,
    ups.LastPostDate,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    COALESCE(SUM(vs.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(vs.DownVotes), 0) AS TotalDownVotes,
    ta.TagName,
    ta.PostCount AS TagPostCount,
    ta.TotalViews AS TagTotalViews,
    ta.AverageScore AS TagAverageScore
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON cp.UserDisplayName = u.DisplayName
LEFT JOIN 
    VoteStats vs ON vs.PostId IN (SELECT PostId FROM RecentPosts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    TagAnalytics ta ON ta.PostCount > 0
WHERE 
    ups.PostCount > 0
GROUP BY 
    u.DisplayName, ups.PostCount, ups.TotalScore, ups.AvgViewCount, ups.LastPostDate, ta.TagName, ta.PostCount
ORDER BY 
    ups.TotalScore DESC, ups.LastPostDate DESC;
