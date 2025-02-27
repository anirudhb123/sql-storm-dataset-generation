WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteBalance
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(COALESCE(PV.VoteTypeId = 2, 0)::int) AS UpvoteCount,
        SUM(COALESCE(PV.VoteTypeId = 3, 0)::int) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes PV ON P.Id = PV.PostId
    GROUP BY 
        P.Id
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.UpvoteCount,
        PS.DownvoteCount,
        PS.RecentPostRank
    FROM 
        PostStats PS
    WHERE 
        PS.RecentPostRank <= 5
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalVotes,
    U.Upvotes,
    U.Downvotes,
    U.VoteBalance,
    TP.Title,
    TP.CommentCount,
    TP.UpvoteCount,
    TP.DownvoteCount
FROM 
    UserVoteStats U
LEFT JOIN 
    TopPosts TP ON U.UserId = TP.OwnerUserId
ORDER BY 
    U.VoteBalance DESC, U.TotalVotes DESC
FETCH FIRST 10 ROWS ONLY;
