WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagName
    WHERE 
        P.PostTypeId = 1 -- Only consider questions
    GROUP BY 
        P.Id
),
PostEditHistory AS (
    SELECT 
        P.Id AS PostId,
        H.CreationDate,
        TH.Name AS HistoryType,
        H.UserDisplayName,
        H.Text
    FROM 
        Posts P
    JOIN 
        PostHistory H ON P.Id = H.PostId
    JOIN 
        PostHistoryTypes TH ON H.PostHistoryTypeId = TH.Id
    WHERE 
        H.PostHistoryTypeId IN (4, 5, 6, 9) -- Filter for edits related to title, body, and tags
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS QuestionsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Only consider questions
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    PScore.TagCount,
    PScore.TagsList,
    E.HistoryType,
    E.CreationDate AS EditDate,
    E.UserDisplayName AS EditedBy,
    E.Text AS EditComment,
    U.DisplayName AS OwnerName,
    U.Reputation,
    TUsers.Upvotes,
    TUsers.Downvotes,
    TUsers.QuestionsCount
FROM 
    Posts P
LEFT JOIN 
    PostTagCounts PScore ON P.Id = PScore.PostId
LEFT JOIN 
    PostEditHistory E ON P.Id = E.PostId
INNER JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    TopUsers TUsers ON U.Id = TUsers.UserId
WHERE 
    P.CreationDate >= '2022-01-01' -- Filter for posts created in 2022
ORDER BY 
    P.ViewCount DESC, 
    P.CreationDate DESC;
