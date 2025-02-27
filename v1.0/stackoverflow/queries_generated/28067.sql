WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        RPAD(rp.Body, 600, '...') AS ShortBody, -- Truncated body for readability
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankPerUser <= 3 -- Top 3 highest scored posts per user
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(fp.PostId) AS PostCount,
        SUM(fp.ViewCount) AS TotalViews,
        SUM(fp.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts fp ON u.Id = fp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.TotalScore,
    pt.TagName,
    pt.TagCount
FROM 
    UserPosts up
CROSS JOIN 
    PopularTags pt
ORDER BY 
    up.TotalScore DESC, 
    pt.TagCount DESC;
