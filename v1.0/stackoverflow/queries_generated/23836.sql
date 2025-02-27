WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), 
UserBadges AS (
    SELECT 
        u.Id AS UserID,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        ub.MaxBadgeClass,
        COALESCE(CHAR_LENGTH(p.Body), 0) AS BodyLength,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c 
            WHERE c.PostId = rp.PostID
        ), 0) AS CommentCount,
        (
            SELECT STRING_AGG(DISTINCT t.TagName, ', ')
            FROM Tags t
            INNER JOIN LATERAL unnest(string_to_array(rp.Tags, '><')) AS tag ON tag = t.TagName
        ) AS TagsList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserID
    LEFT JOIN 
        Posts p ON rp.PostID = p.Id
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.BadgeCount,
    pd.MaxBadgeClass,
    pd.BodyLength,
    pd.CommentCount,
    pd.TagsList,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score'
        ELSE COALESCE(CONCAT('Score: ', pd.Score), 'No Score')
    END AS ScoreInfo,
    CASE 
        WHEN pd.BadgeCount IS NULL THEN 'No Badges'
        WHEN pd.BadgeCount = 0 THEN 'No Badges'
        ELSE CONCAT(pd.BadgeCount, ' Badges (Max Class: ', pd.MaxBadgeClass, ')')
    END AS BadgeInfo,
    CASE 
        WHEN pd.ViewCount < 50 THEN 'Low Engagement'
        WHEN pd.ViewCount BETWEEN 50 AND 200 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM 
    PostDetails pd
WHERE 
    pd.BadgeCount IS NOT NULL 
    OR pd.BodyLength > 0
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;


This SQL query consists of common table expressions (CTEs) to gather relevant metrics about posts, their owners, and associated badges. The query includes various constructs including window functions for ranking posts, correlated subqueries for counting comments, and string aggregation for tags. It computes conditional logic outputs based on different metrics. The result is filtered and limited for performance benchmarking, making it ideal for assessing both the logic complexity and the potential execution speed.
