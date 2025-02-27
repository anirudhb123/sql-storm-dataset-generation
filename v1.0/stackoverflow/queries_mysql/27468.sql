
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS Author,
        u.Reputation,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
TagSummary AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
             UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1,
            (SELECT @rownum := 0) t2) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagSummary
    WHERE 
        PostCount > 10  
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalScore,
    P.Title,
    P.Author,
    P.Reputation,
    P.Score AS PostScore,
    P.CommentCount,
    P.CreationDate
FROM 
    TopTags T
JOIN 
    RankedPosts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
WHERE 
    T.TagRank <= 5  
ORDER BY 
    T.TotalScore DESC, 
    P.Score DESC;
