WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, GETDATE())  -- Posts created in the last 30 days
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
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
),
TagViews AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        COUNT(DISTINCT p.Id) AS AssociatedPostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.Id, t.TagName, t.Count
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.UserId AS PostOwnerId,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ph.HistoryDate,
    ph.UserDisplayName AS HistoryUser,
    ph.Comment AS HistoryComment,
    tv.TagId,
    tv.TagName,
    tv.AssociatedPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users ub ON rp.OwnerUserId = ub.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryInfo ph ON ph.PostId = rp.PostId
LEFT JOIN 
    Tags tv ON tv.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, ','))
WHERE 
    rp.Rank <= 10  -- Only return top 10 posts per type
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate DESC;
