WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END), 0) AS Score
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND P.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
CombinedStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.CommentCount,
        PS.VoteCount,
        PS.UpvoteCount,
        PS.DownvoteCount,
        PS.Score,
        US.UserId,
        US.DisplayName,
        US.PostCount,
        US.BadgeCount,
        US.TotalUpVotes,
        US.TotalDownVotes
    FROM 
        PostStats PS
    JOIN 
        Users US ON PS.PostId IN (
            SELECT Id FROM Posts WHERE OwnerUserId = US.UserId
        )
)
SELECT 
    CS.Title,
    CS.CommentCount,
    CS.VoteCount,
    CS.UpvoteCount,
    CS.DownvoteCount,
    CS.Score,
    US.DisplayName,
    US.PostCount,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    CombinedStats CS
JOIN 
    Users US ON CS.UserId = US.Id
ORDER BY 
    CS.Score DESC, CS.CreationDate DESC
LIMIT 20;
