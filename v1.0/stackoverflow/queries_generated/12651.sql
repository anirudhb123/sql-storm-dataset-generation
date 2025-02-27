-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL (SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagName) T ON TRUE
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, P.ViewCount, P.Score, P.AnswerCount
),

UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    P.PostId,
    P.Title,
    P.CreationDate,
    P.LastActivityDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    U.UserId,
    U.DisplayName,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.BadgeCount
FROM 
    PostStatistics P
JOIN 
    Users U ON P.OwnerUserId = U.Id
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 100;
