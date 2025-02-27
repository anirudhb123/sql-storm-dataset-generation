WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 10 +
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) * 5 +
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS TotalBadgeScore
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.PostTypeId IN (1, 2) 
            THEN 'Interaction Post'
            ELSE 'Reference Post'
        END AS PostCategory,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostedTags AS (
    SELECT DISTINCT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
CombinedData AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.ViewCount,
        pi.Score,
        pi.OwnerDisplayName,
        pi.PostCategory,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        cp.ClosedDate,
        cp.CloseReasons,
        pt.Tags,
        RANK() OVER (ORDER BY pi.Score DESC NULLS LAST) AS RankScore
    FROM 
        PostInfo pi
    LEFT JOIN 
        UserBadges ub ON pi.OwnerDisplayName = ub.UserId::varchar
    LEFT JOIN 
        ClosedPosts cp ON pi.PostId = cp.PostId
    LEFT JOIN 
        PostedTags pt ON pi.PostId = pt.PostId
    WHERE 
        pi.RowNum = 1
        AND (ub.GoldBadges > 0 OR ub.SilverBadges > 0) 
        AND (cp.ClosedDate IS NULL OR pi.Score > 10)
)
SELECT 
    *,
    CASE 
        WHEN ClosedDate IS NOT NULL 
        THEN 'Closed post, potentially unresolved issues'
        ELSE 'Open post with engagement'
    END AS PostStatus,
    CASE 
        WHEN Tags IS NOT NULL THEN 
            'Contains tags: ' || Tags
        ELSE 
            'No associated tags'
    END AS TagInfo
FROM 
    CombinedData
WHERE 
    RankScore <= 50
ORDER BY 
    RankScore, ViewCount DESC;
