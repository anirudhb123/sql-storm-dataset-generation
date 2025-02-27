WITH RECURSIVE UserScore AS (
    SELECT 
        U.Id AS UserId,
        SUM(V.BountyAmount) AS TotalBounty
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
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes, -- Counting UpVotes
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes, -- Counting DownVotes
        MAX(P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.LastActivityDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
), 
FilteredPostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.LastActivityDate,
        (PS.UpVotes - PS.DownVotes) AS NetScore
    FROM 
        PostStats PS
    WHERE 
        PS.CommentCount > 0 AND -- Only posts with comments
        (PS.UpVotes - PS.DownVotes) > 0 -- Positive net score
), 
RankedPosts AS (
    SELECT 
        FPS.*,
        RANK() OVER (ORDER BY FPS.NetScore DESC) AS Rank
    FROM 
        FilteredPostStats FPS
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UPS.TotalBounty,
    RP.PostId,
    RP.Title,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.NetScore,
    RP.Rank
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
JOIN 
    UserScore UPS ON U.Id = UPS.UserId
WHERE 
    U.Reputation > 1000 -- Top users with more than 1000 reputation
ORDER BY 
    RP.Rank
OPTION (MAXRECURSION 100);

