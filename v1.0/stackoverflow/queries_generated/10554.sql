-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.VoteTypeId = 2) AS UpVotes, -- Count of Upvotes
        SUM(V.VoteTypeId = 3) AS DownVotes, -- Count of Downvotes
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers, -- Count of answers for Questions
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.CommentCount ELSE 0 END) AS TotalComments -- Count of comments for Questions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TagsStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Tags) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.UpVotes,
    US.DownVotes,
    US.TotalAnswers,
    US.TotalComments,
    TS.PostCount AS TagPostCount,
    TS.TagId,
    TS.TagName
FROM 
    UserStats US
LEFT JOIN 
    TagsStats TS ON US.PostCount > 0 -- Only join if user has posts
ORDER BY 
    US.PostCount DESC, US.UpVotes DESC;
