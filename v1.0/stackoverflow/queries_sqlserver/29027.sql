
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(fp.PostId) AS TotalPosts,
        AVG(DATALENGTH(fp.Body)) AS AvgBodyLength,
        STRING_AGG(fp.Title, '; ') AS TopTitles
    FROM 
        FilteredPosts fp
    JOIN 
        (SELECT DISTINCT 
             value AS TagName 
         FROM 
             STRING_SPLIT(fp.Tags, '>')) t ON t.TagName IN (SELECT value FROM STRING_SPLIT(fp.Tags, '>'))
    GROUP BY 
        t.TagName
)
SELECT 
    ts.TagName,
    ts.TotalPosts,
    ts.AvgBodyLength,
    ts.TopTitles,
    CASE 
        WHEN ts.TotalPosts > 10 THEN 'Active' 
        ELSE 'Less Active' 
    END AS ActivityStatus
FROM 
    TagStatistics ts
ORDER BY 
    ts.TotalPosts DESC;
