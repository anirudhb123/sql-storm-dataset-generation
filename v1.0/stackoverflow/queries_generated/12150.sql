-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        T.TagName
),
PostHistoryTypesCount AS (
    SELECT 
        PHT.Name AS PostHistoryType,
        COUNT(PH.Id) AS ChangeCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PHT.Name
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.UpVotes,
    U.DownVotes,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.CommentCount AS TagCommentCount,
    PHTC.PostHistoryType,
    PHTC.ChangeCount AS HistoryChangeCount
FROM 
    UserStatistics U
LEFT JOIN 
    TagStatistics T ON U.UserId = (SELECT TOP 1 Id FROM Users ORDER BY NEWID())  -- Random user for demonstration
LEFT JOIN 
    PostHistoryTypesCount PHTC ON PHTC.ChangeCount > 0
ORDER BY 
    U.UpVotes DESC, U.TotalPosts DESC;
