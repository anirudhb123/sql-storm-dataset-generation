
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
        PT.Name AS PostType,
        (SELECT GROUP_CONCAT(T.TagName SEPARATOR '; ')
         FROM Tags T 
         WHERE P.Tags LIKE CONCAT('%', T.TagName, '%')) AS RelatedTags,
        CHAR_LENGTH(P.Body) AS BodyLength,
        CHAR_LENGTH(P.Title) AS TitleLength,
        @row_num := IF(@prev_post_id = P.Id, @row_num + 1, 1) AS RevisionRank,
        @prev_post_id := P.Id
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        Users U ON PH.UserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id,
        (SELECT @row_num := 0, @prev_post_id := 0) AS vars
    WHERE 
        PH.PostHistoryTypeId IN (1, 4, 5)  
)
SELECT 
    GROUP_CONCAT(CONCAT('Post ID: ', PostId, 
                       '; Post Title: ', Title,
                       '; Length of Title: ', TitleLength,
                       '; Length of Body: ', BodyLength,
                       '; Last Editor: ', EditorDisplayName,
                       '; Date Edited: ', CreationDate,
                       '; Tags: ', RelatedTags) 
                SEPARATOR ' | ') AS PostSummary,
    UserDisplayName
FROM 
    StringBenchmark
WHERE 
    RevisionRank = 1  
GROUP BY 
    UserDisplayName
ORDER BY 
    UserDisplayName;
