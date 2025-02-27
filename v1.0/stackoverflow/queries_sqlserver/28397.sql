
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.ViewCount > 100  
),
TagStats AS (
    SELECT 
        TAG,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM (
        SELECT 
            value AS TAG,
            Score
        FROM 
            Posts
        CROSS APPLY STRING_SPLIT(TRIM(REPLACE(REPLACE(Tags, '<', ''), '>', '')), '>') AS t
        WHERE 
            PostTypeId = 1  
    ) AS p
    GROUP BY TAG
),
TopTags AS (
    SELECT 
        TAG,
        PostCount,
        TotalScore,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tt.TAG AS TopTag,
    tt.PostCount,
    tt.TotalScore,
    tt.AverageScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.TAG IN (SELECT value FROM STRING_SPLIT(TRIM(REPLACE(REPLACE(rp.Tags, '<', ''), '>', '')), '>'))
WHERE 
    rp.Rank = 1  
ORDER BY 
    tt.TotalScore DESC, rp.ViewCount DESC;
