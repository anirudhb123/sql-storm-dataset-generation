WITH TagDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        T.TagName,
        P.Tags,
        PH.UserId AS EditorId,
        PH.UserDisplayName AS EditorDisplayName,
        PH.CreationDate AS LastEditDate,
        PH.PostHistoryTypeId,
        PH.Comment
    FROM Posts P 
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[]) 
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1  -- Filtering for Questions
        AND PH.PostHistoryTypeId IN (4, 5, 6, 11)  -- Filter for relevant edit history types
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueAuthors,
        COUNT(DISTINCT EditorId) AS UniqueEditors,
        MAX(LastEditDate) AS LastEdited
    FROM TagDetails
    GROUP BY TagName
),
DetailedStats AS (
    SELECT 
        T.TagName,
        T.TotalPosts,
        T.UniqueAuthors,
        T.UniqueEditors,
        T.LastEdited,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId IN (SELECT PostId FROM TagDetails WHERE TagName = T.TagName) AND V.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId IN (SELECT PostId FROM TagDetails WHERE TagName = T.TagName) AND V.VoteTypeId = 3), 0) AS Downvotes
    FROM TagStats T
)
SELECT 
    TagName,
    TotalPosts,
    UniqueAuthors,
    UniqueEditors,
    LastEdited,
    Upvotes,
    Downvotes
FROM DetailedStats
ORDER BY TotalPosts DESC, Upvotes DESC;
