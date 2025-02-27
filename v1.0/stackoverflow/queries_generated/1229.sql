WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 4 THEN 1 ELSE 0 END) AS OffensiveVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Posts that have been closed
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    P.Title AS PostTitle,
    P.CommentCount,
    P.TotalUpVotes,
    P.TotalDownVotes,
    CP.CloseCount,
    CP.LastClosedDate,
    P2.Title AS RelatedPost
FROM 
    UserVoteSummary U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON P.Id = CP.PostId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Posts P2 ON PL.RelatedPostId = P2.Id
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
    AND (U.UpVotes > U.DownVotes OR U.TotalVotes > 50)
ORDER BY 
    U.TotalVotes DESC, 
    P.CommentCount DESC
LIMIT 100;
