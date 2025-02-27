-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.CreationDate IS NOT NULL) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(STRING_TO_ARRAY(P.Tags, ','))
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    U.DisplayName AS User,
    U.TotalPosts,
    U.TotalComments,
    U.TotalVotes,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    P.TotalComments AS PostTotalComments,
    P.UpVotes,
    P.DownVotes,
    T.TagName AS PostTag,
    T.TotalPosts AS TagPostCount
FROM 
    UserStats U
LEFT JOIN 
    PostStats P ON U.UserId = P.Id
LEFT JOIN 
    TagStats T ON P.PostId IN (SELECT Unnest(STRING_TO_ARRAY(P.Tags, ',')))
ORDER BY 
    U.TotalPosts DESC, P.Score DESC;
