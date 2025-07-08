
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
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01') 
),
TagSummary AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts,
        LATERAL SPLIT_TO_TABLE(Tags, ',') AS value
    GROUP BY 
        TRIM(value)
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
    RankedPosts P ON POSITION(T.TagName IN P.Tags) > 0
WHERE 
    T.TagRank <= 5  
ORDER BY 
    T.TotalScore DESC, 
    P.Score DESC;
