WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering Questions and Answers
),

PostTags AS (
    SELECT 
        rp.PostId, 
        unnest(string_to_array(rp.Tags, '><')) AS TagName
    FROM 
        RankedPosts rp
),

TagStats AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount,
        COUNT(*) AS TotalPostsWithTag
    FROM 
        PostTags
    GROUP BY 
        TagName
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Class
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    tp.TagName,
    ts.PostCount,
    ts.TotalPostsWithTag,
    ub.UserId,
    ub.BadgeCount AS UserBadges,
    phs.EditCount,
    phs.ClosedCount,
    phs.ReopenedCount
FROM 
    RankedPosts rp
JOIN 
    PostTags tp ON rp.PostId = tp.PostId
JOIN 
    TagStats ts ON tp.TagName = ts.TagName
JOIN 
    UserBadges ub ON rp.OwnerDisplayName = ub.UserId
JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.RecentPostRank = 1
ORDER BY 
    rp.CreationDate DESC, ts.PostCount DESC;
