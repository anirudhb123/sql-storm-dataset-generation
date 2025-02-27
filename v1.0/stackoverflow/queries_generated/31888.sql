WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS TotalDownvotedPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastCloseDate,
        ct.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ct.Name
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.TotalPosts,
    up.TotalUpvotedPosts,
    up.TotalDownvotedPosts,
    up.AverageScore,
    up.TotalViewCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS RecentPostDate,
    rp.OwnerDisplayName AS RecentPostOwner,
    pcr.CloseReason,
    pcr.LastCloseDate,
    tb.TagName
FROM 
    UserPostStats up
LEFT JOIN 
    RecentPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1 -- Most recent post for each user
LEFT JOIN 
    PostCloseReasons pcr ON rp.PostId = pcr.PostId
LEFT JOIN 
    TopTags tb ON tb.TagName = ANY (string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    up.TotalPosts > 5
ORDER BY 
    up.TotalPosts DESC, rp.CreationDate DESC;
