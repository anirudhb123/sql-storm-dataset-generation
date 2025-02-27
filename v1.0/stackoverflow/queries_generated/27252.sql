WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        P.LastEditDate,
        P.Score,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Focus on questions only
        AND P.CreationDate >= NOW() - INTERVAL '1 year'  -- Within the last year
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.Score > 5 THEN 1 ELSE 0 END) AS HighScoreCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])  -- Array of tags
    GROUP BY 
        T.TagName
),
CloseReasonDetails AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(CRT.Name AS varchar), ', ') AS CloseReasonNames
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.Tags,
    RP.AnswerCount,
    RP.CommentCount,
    RP.CreationDate,
    RP.LastEditDate,
    RP.Score,
    RP.Author,
    RP.ScoreRank,
    TS.PostCount AS RelatedTagPostCount,
    TS.HighScoreCount,
    TS.AverageScore,
    CRD.CloseCount,
    CRD.CloseReasonNames
FROM 
    RankedPosts RP
LEFT JOIN 
    TagStatistics TS ON TS.TagName = ANY(string_to_array(RP.Tags, ','))  -- Fetch related tags statistics
LEFT JOIN 
    CloseReasonDetails CRD ON CRD.PostId = RP.PostId
WHERE 
    RP.ScoreRank = 1  -- Fetch top post for each author
ORDER BY 
    RP.Score DESC;
