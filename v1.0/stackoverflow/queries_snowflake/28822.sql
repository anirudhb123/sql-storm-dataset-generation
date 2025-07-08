
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM VALUE) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><'))) AS VALUE)
    WHERE 
        TagRank <= 5 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagPopularity
    FROM 
        FilteredTags
)
SELECT 
    tt.TagName,
    tt.PostCount,
    p.Title,
    p.Score,
    u.DisplayName AS UserCreator,
    p.CreationDate
FROM 
    TopTags tt
JOIN 
    Posts p ON tt.TagName IN (SELECT VALUE FROM TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))))
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    tt.TagPopularity <= 10 
ORDER BY 
    tt.PostCount DESC, p.Score DESC;
