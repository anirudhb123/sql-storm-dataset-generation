
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.PostId IS NOT NULL THEN 1 END) AS EditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.EditCount,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats PS, (SELECT @rank := 0) r
    WHERE 
        PS.Score > 10
    ORDER BY 
        PS.Score DESC, PS.ViewCount DESC
)
SELECT 
    UVS.DisplayName,
    UVS.Upvotes,
    UVS.Downvotes,
    UVS.TotalVotes,
    TP.Title AS PostTitle,
    TP.Score AS PostScore,
    TP.ViewCount,
    TP.CommentCount,
    TP.EditCount,
    UB.BadgeCount,
    UB.BadgeNames
FROM 
    UserVoteStats UVS
JOIN 
    TopPosts TP ON UVS.UserId = TP.PostId
JOIN 
    (SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id) UB ON UVS.UserId = UB.UserId
WHERE 
    TP.Rank <= 10
ORDER BY 
    UVS.TotalVotes DESC, UVS.Upvotes DESC;
