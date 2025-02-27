WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body, 
        P.CreationDate, 
        P.OwnerUserId, 
        U.DisplayName AS OwnerDisplayName,
        string_agg(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><') AS TagIds ON true
    LEFT JOIN 
        Tags T ON TagIds::int = T.Id
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.OwnerUserId, U.DisplayName
),
PostMetrics AS (
    SELECT 
        TP.PostId, 
        TP.Title, 
        TP.Body, 
        TP.CreationDate, 
        TP.OwnerUserId, 
        TP.OwnerDisplayName,
        COALESCE(answers.AnswerCount, 0) AS AnswerCount,
        COALESCE(comments.CommentCount, 0) AS CommentCount,
        COALESCE(votes.VoteCount, 0) AS VoteCount
    FROM 
        TaggedPosts TP
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 -- Only Answers
        GROUP BY 
            ParentId
    ) AS answers ON TP.PostId = answers.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) AS comments ON TP.PostId = comments.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS votes ON TP.PostId = votes.PostId
)

SELECT 
    PM.Title, 
    PM.CreationDate, 
    PM.OwnerDisplayName, 
    PM.AnswerCount, 
    PM.CommentCount, 
    PM.VoteCount,
    PM.Body,
    PM.Tags
FROM 
    PostMetrics PM
ORDER BY 
    PM.VoteCount DESC, 
    PM.AnswerCount DESC
LIMIT 10;
