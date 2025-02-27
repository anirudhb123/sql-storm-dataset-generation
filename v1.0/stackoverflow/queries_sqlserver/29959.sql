
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TagStatistics AS (
    SELECT
        value AS Tag,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '> <') AS TagList
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStatistics
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalScore,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON tp.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '> <'))
WHERE 
    tp.ScoreRank <= 5 
    AND rp.Rank = 1 
ORDER BY 
    tp.TotalScore DESC, rp.CreationDate DESC;
