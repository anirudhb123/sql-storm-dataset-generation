WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(coalesce(p.ViewCount, 0)) AS TotalViews,
        AVG(coalesce(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '1 year'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostTagStats AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagPostCount,
        AVG(pt.ViewCount) AS AvgTagViewCount
    FROM 
        Tags t
    LEFT JOIN 
        LATERAL (
            SELECT 
                p.Id AS PostId, 
                p.ViewCount
            FROM 
                Posts p 
            WHERE 
                p.Tags LIKE '%' || t.TagName || '%'
        ) pt ON true
    GROUP BY 
        t.TagName
),
CloseReasonCounts AS (
    SELECT 
        ph.Comment AS CloseReason,
        COUNT(*) AS Count
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.Comment
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.PostCount,
    ua.TotalViews,
    ua.AvgScore,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(rp.PostId, 0) AS TopPostId,
    COALESCE(rp.Title, 'No posts') AS TopPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS TopPostCreationDate,
    COALESCE(rp.ViewCount, 0) AS TopPostViewCount,
    COALESCE(rp.Score, 0) AS TopPostScore,
    pt.TagPostCount,
    pt.AvgTagViewCount,
    cr.CloseReason,
    cr.Count AS CloseReasonCount
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostTagStats pt ON pt.TagPostCount > 0
LEFT JOIN 
    CloseReasonCounts cr ON cr.Count > 0
WHERE 
    (ua.PostCount > 5 OR ua.TotalViews > 100) 
    AND (u.Reputation > 1000 OR u.EmailHash IS NOT NULL)
ORDER BY 
    ua.TotalViews DESC,
    u.Reputation DESC
LIMIT 50;
