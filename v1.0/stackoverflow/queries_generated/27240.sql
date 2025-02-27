WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0 AND 
        p.PostTypeId = 1 -- Only questions
),
TagStats AS (
    SELECT 
        TRIM(t.TagName) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        TRIM(t.TagName)
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
FilteredUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.Reputation,
        ub.BadgeCount,
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        UserBadgeCounts ub
    JOIN 
        RankedPosts rp ON ub.UserId = rp.OwnerDisplayName
    WHERE 
        ub.BadgeCount > 5 -- Users with more than 5 badges
)
SELECT 
    fu.UserId,
    fu.DisplayName,
    fu.Reputation,
    fu.BadgeCount,
    COUNT(DISTINCT fu.PostId) AS NumberOfPosts,
    SUM(fu.ViewCount) AS TotalPostViews,
    SUM(fu.Score) AS TotalPostScore,
    STRING_AGG(DISTINCT ctl.TagName, ', ') AS AssociatedTags
FROM 
    FilteredUsers fu
JOIN 
    TagStats ctl ON fu.Tags LIKE '%' || ctl.TagName || '%'
GROUP BY 
    fu.UserId, fu.DisplayName, fu.Reputation, fu.BadgeCount
ORDER BY 
    TotalPostScore DESC, TotalPostViews DESC;
