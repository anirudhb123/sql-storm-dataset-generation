WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.CommentCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Considering only questions
        AND P.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),

TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        AVG(CASE WHEN CommentCount > 0 THEN CommentCount ELSE NULL END) AS AvgComments
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),

TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 10 -- Only users with more than 10 questions
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    TS.TagName,
    TS.PostCount,
    TS.UpvotedPosts,
    TS.AvgComments,
    TU.DisplayName AS TopUser,
    TU.TotalScore
FROM 
    RankedPosts RP
LEFT JOIN 
    TagStats TS ON RP.Tags LIKE '%' || TS.TagName || '%'
LEFT JOIN 
    TopUsers TU ON TU.UserId = RP.OwnerUserId
WHERE 
    RP.Rank <= 3 -- Top 3 recent questions per tag
ORDER BY 
    TS.PostCount DESC, 
    RP.CreationDate DESC;
