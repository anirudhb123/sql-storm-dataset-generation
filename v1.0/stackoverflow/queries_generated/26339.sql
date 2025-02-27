WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        u.DisplayName AS OwnerName, 
        p.CreationDate, 
        p.ViewCount, 
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS QuestionCount, 
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CreationDate,
    rp.ViewCount,
    ra.QuestionCount,
    ra.TotalViews,
    ra.AvgScore,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserActivity ra ON rp.PostRank = 1 AND ra.UserId = rp.OwnerUserId
JOIN 
    TopTags tt ON true
WHERE 
    rp.TagCount > 0
ORDER BY 
    rp.Score DESC, 
    ra.TotalViews DESC
LIMIT 100;
