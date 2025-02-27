
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
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TagStatistics AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<', -1), '>', 1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<', -1), '>', 1)
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
    RankedPosts rp ON FIND_IN_SET(tp.Tag, REPLACE(REPLACE(rp.Tags, '<', ''), '>', ''))
WHERE 
    tp.ScoreRank <= 5 
    AND rp.Rank = 1 
ORDER BY 
    tp.TotalScore DESC, rp.CreationDate DESC;
