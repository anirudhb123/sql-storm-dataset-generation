
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    WHERE 
        p.PostTypeId = 1
),
TagAnalytics AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        MIN(CreationDate) AS FirstPostDate,
        MAX(CreationDate) AS LastPostDate
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        FirstPostDate,
        LastPostDate,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagAnalytics
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.FirstPostDate,
    t.LastPostDate,
    p.OwnerDisplayName AS TopPostOwner,
    p.Title AS TopPostTitle
FROM 
    TopTags t
JOIN 
    RankedPosts p ON FIND_IN_SET(t.TagName, p.Tags)
WHERE 
    t.ViewRank <= 5
ORDER BY 
    t.ViewRank, t.TotalViews DESC;
