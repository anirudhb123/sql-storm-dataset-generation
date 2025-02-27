
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
            SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '>', n.n), '>', -1) AS TAG,
            Score
        FROM 
            Posts
        JOIN 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n ON CHAR_LENGTH(TRIM(BOTH '<>' FROM Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM Tags), '>', '')) >= n.n - 1
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
    TopTags tt ON tt.Tag IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM rp.Tags), '>', n.n), '>', -1) AS TAG
                               FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
                               WHERE CHAR_LENGTH(TRIM(BOTH '<>' FROM rp.Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM rp.Tags), '>', '')) >= n.n - 1)  
WHERE 
    rp.Rank = 1  
ORDER BY 
    tt.TotalScore DESC, rp.ViewCount DESC;
