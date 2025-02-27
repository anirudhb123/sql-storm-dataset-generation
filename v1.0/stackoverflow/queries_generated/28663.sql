WITH TagDetails AS (
    SELECT 
        T.TagName,
        P.Title AS PostTitle,
        P.Body AS PostBody,
        P.Tags AS PostTags,
        PH.CreationDate AS HistoryDate,
        PH.Comment AS EditComment,
        PH.UserDisplayName AS EditorDisplayName,
        PH.PostHistoryTypeId
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        Tags T ON T.Id = (SELECT MIN(Id) FROM Tags WHERE Position(T.TagName IN SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2)) > 0)
    WHERE 
        P.PostTypeId = 1 
        AND PH.PostHistoryTypeId IN (4, 5, 6) 
        AND PH.CreationDate >= '2022-01-01'
),
ProcessedEditDetails AS (
    SELECT 
        TagName,
        PostTitle,
        PostBody,
        PostTags,
        HistoryDate,
        EditorDisplayName,
        ROW_NUMBER() OVER(PARTITION BY TagName ORDER BY HistoryDate DESC) AS EditRank
    FROM 
        TagDetails
),
FinalOutput AS (
    SELECT 
        TagName,
        PostTitle,
        LENGTH(PostBody) AS BodyLength,
        LENGTH(PostTags) AS TagsLength,
        EditRank,
        EditorDisplayName
    FROM 
        ProcessedEditDetails
    WHERE 
        EditRank <= 3
)
SELECT 
    TagName,
    COUNT(PostTitle) AS TotalPosts,
    AVG(BodyLength) AS AverageBodyLength,
    AVG(TagsLength) AS AverageTagsLength,
    STRING_AGG(DISTINCT EditorDisplayName, ', ') AS Editors
FROM 
    FinalOutput
GROUP BY 
    TagName
ORDER BY 
    TotalPosts DESC
LIMIT 10;
