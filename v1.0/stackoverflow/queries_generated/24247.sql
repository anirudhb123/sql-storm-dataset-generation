WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpvoteCount, -- Count of upvotes
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownvoteCount, -- Count of downvotes
        (COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) - COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3)) AS NetVotes
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
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS HistoryCount,
        COALESCE(SUM(CASE WHEN P2.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS RelatedPostCount,
        AVG(COALESCE(U.UpvoteCount, 0) - COALESCE(U.DownvoteCount, 0)) AS AverageUserNetVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN 
        Posts P2 ON PL.RelatedPostId = P2.Id
    LEFT JOIN 
        UserVoteCounts U ON U.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        P.Id
),
Ranking AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.HistoryCount,
        PS.RelatedPostCount,
        PS.AverageUserNetVotes,
        RANK() OVER (ORDER BY PS.CommentCount DESC, PS.HistoryCount DESC, PS.AverageUserNetVotes DESC) AS PostRank
    FROM 
        PostStats PS
)
SELECT 
    U.DisplayName,
    R.Title,
    R.CommentCount,
    R.HistoryCount,
    R.RelatedPostCount,
    R.AverageUserNetVotes,
    CASE 
        WHEN R.AverageUserNetVotes > 0 THEN 'Positive'
        WHEN R.AverageUserNetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS UserVoteStatus
FROM 
    Ranking R
JOIN 
    Users U ON R.OwnerUserId = U.Id
WHERE 
    R.PostRank <= 10 -- Top 10 posts
ORDER BY 
    R.PostRank;
