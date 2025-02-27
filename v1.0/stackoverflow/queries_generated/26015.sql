WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Comments) OVER(PARTITION BY P.Id) AS TotalComments,
        RANK() OVER(PARTITION BY P.Tags ORDER BY P.Score DESC) AS RankWithinTag
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 -- We are only looking for Questions
        AND P.CreationDate >= DATEADD(YEAR, -2, GETDATE()) -- Posts created within the last 2 years
),
FilteredRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Body,
        OwnerDisplayName,
        TotalComments,
        RankWithinTag
    FROM 
        RankedPosts
    WHERE 
        TotalComments > 5 -- Filter to only include posts with more than 5 comments
)
SELECT 
    R.Tags,
    COUNT(R.PostId) AS PostCount,
    AVG(R.TotalComments) AS AvgComments,
    STRING_AGG(R.OwnerDisplayName, ', ') AS Owners,
    STRING_AGG(R.Title, '; ') AS Titles
FROM 
    FilteredRankedPosts R
GROUP BY 
    R.Tags
HAVING 
    COUNT(R.PostId) >= 3 -- Only include tags with at least 3 questions
ORDER BY 
    PostCount DESC, 
    AvgComments DESC;
