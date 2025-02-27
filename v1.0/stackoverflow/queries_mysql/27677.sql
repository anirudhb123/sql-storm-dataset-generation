
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= TIMESTAMPADD(YEAR, -1, '2024-10-01 12:34:56')
),

TagSummary AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalScore,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagSummary
)

SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalScore,
    TT.AverageScore,
    P.Title,
    P.Body,
    P.OwnerName,
    P.CreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.AnswerCount AS PostAnswerCount
FROM 
    TopTags TT
JOIN 
    RankedPosts P ON FIND_IN_SET(TT.TagName, REPLACE(P.Tags, '>', ',')) > 0
WHERE 
    TT.Rank <= 5 
ORDER BY 
    TT.TotalScore DESC, P.CreationDate DESC;
