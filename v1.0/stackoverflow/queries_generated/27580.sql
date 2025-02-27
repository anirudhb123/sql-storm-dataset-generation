WITH StringBenchmark AS (
    SELECT 
        PH.Id AS PostHistoryId,
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS UserDisplayName,
        PH.Comment,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.Text AS NewValue,
        PH.UserId,
        PH.UserDisplayName AS EditorDisplayName,
        PH.CreationDate,
        PT.Name AS PostType,
        STUFF((SELECT '; ' + T.TagName 
               FROM Tags T 
               WHERE P.Tags LIKE '%' + T.TagName + '%'
               FOR XML PATH('')), 1, 2, '') AS RelatedTags,
        CHAR_LENGTH(P.Body) AS BodyLength,
        CHAR_LENGTH(P.Title) AS TitleLength,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS RevisionRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        Users U ON PH.UserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PH.PostHistoryTypeId IN (1, 4, 5)  -- Initial titles, titles edits, body edits
)
SELECT 
    STRING_AGG(CONCAT('Post ID: ', PostId, 
                      '; Post Title: ', Title,
                      '; Length of Title: ', TitleLength,
                      '; Length of Body: ', BodyLength,
                      '; Last Editor: ', EditorDisplayName,
                      '; Date Edited: ', CreationDate,
                      '; Tags: ', RelatedTags), 
                ' | ') AS PostSummary
FROM 
    StringBenchmark
WHERE 
    RevisionRank = 1  -- Only take the latest revision for each post
GROUP BY 
    UserDisplayName
ORDER BY 
    UserDisplayName;
