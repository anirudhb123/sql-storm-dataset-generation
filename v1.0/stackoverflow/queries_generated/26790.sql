WITH TagAnalysis AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagVotes AS (
    SELECT 
        Ta.Tag,
        COUNT(DISTINCT V.UserId) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId = 3 THEN V.UserId END) AS DownvoteCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        TagAnalysis Ta
    LEFT JOIN 
        Posts P ON Ta.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        Ta.Tag
),
TagHistory AS (
    SELECT 
        Ta.Tag,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM 
        TagAnalysis Ta
    JOIN 
        PostHistory PH ON PH.PostId IN (SELECT Id FROM Posts WHERE Tag = Ta.Tag)
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        Ta.Tag
),
FinalTagStatistics AS (
    SELECT 
        T.Tag,
        T.UpvoteCount,
        T.DownvoteCount,
        T.CommentCount,
        H.EditCount,
        H.UniqueEditors
    FROM 
        TagVotes T
    JOIN 
        TagHistory H ON T.Tag = H.Tag
)
SELECT 
    FT.Tag,
    FT.UpvoteCount,
    FT.DownvoteCount,
    FT.CommentCount,
    FT.EditCount,
    FT.UniqueEditors,
    (FT.UpvoteCount - FT.DownvoteCount) AS NetVotes,
    (COALESCE(NULLIF(FT.UpvoteCount, 0), 1) / COALESCE(NULLIF(FT.CommentCount, 0), 1)) AS ThreadQualityIndex
FROM 
    FinalTagStatistics FT
ORDER BY 
    NetVotes DESC, ThreadQualityIndex DESC;
