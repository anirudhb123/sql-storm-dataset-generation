-- Performance Benchmarking SQL Query
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Users.DisplayName AS OwnerDisplayName,
        COUNT(Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Users.DisplayName
),
TagStats AS (
    SELECT 
        Tags.TagName AS TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = Posts.Id
    GROUP BY 
        Tags.TagName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CloseVotes,
    T.TagName,
    TS.PostCount
FROM 
    PostStats AS PS
LEFT JOIN 
    TagStats AS TS ON PS.PostId = TS.PostCount
ORDER BY 
    PS.UpVotes DESC, PS.CommentCount DESC;
