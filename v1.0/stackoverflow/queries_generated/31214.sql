WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.PostTypeId, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.ViewCount > 10
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS APPLY (
        SELECT 
            TRIM(value) AS TagName 
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) t
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.UserId, 
    u.DisplayName,
    up.PostCount, 
    up.TotalScore, 
    up.AvgViewCount, 
    COALESCE(ub.BadgeCount, 0) AS BadgeCount, 
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    rp.Title AS HighestRankedPostTitle,
    rp.Score AS HighestRankedPostScore,
    rp.ViewCount AS HighestRankedPostViewCount,
    pt.Tags AS PostTags
FROM 
    UserPostCounts up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT TOP 1 OwnerUserId FROM Posts p WHERE p.Score = rp.Score AND p.ViewCount = rp.ViewCount)
LEFT JOIN 
    PostTags pt ON pt.PostId = rp.Id
WHERE 
    up.PostCount > 5
ORDER BY 
    up.TotalScore DESC, 
    up.PostCount DESC;
