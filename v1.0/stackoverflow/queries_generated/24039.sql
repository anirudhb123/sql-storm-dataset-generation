WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (SELECT UNNEST(string_to_array(p.Tags, '><')) AS TagName) t ON TRUE
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pp.Title,
    pp.Views AS TotalViews,
    pp.CommentCount,
    pp.UpVoteCount,
    pp.DownVoteCount,
    ph.LastClosedDate,
    ph.DeleteCount,
    CASE 
        WHEN pp.RankByViews <= 5 THEN 'Top View Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN pp.UpVoteCount * 1.0 / NULLIF(pp.CommentCount, 0) > 2 THEN 'Highly Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CONCAT(ARRAY_TO_STRING(pp.Tags, ', '), ' (Tags)') AS TagList
FROM 
    UserAnalytics ua
LEFT JOIN 
    RankedPosts pp ON ua.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistorySummary ph ON pp.PostId = ph.PostId
WHERE 
    ua.Reputation > 1000 AND 
    pp.LastClosedDate IS NULL
ORDER BY 
    ua.Reputation DESC, pp.TotalViews DESC;
