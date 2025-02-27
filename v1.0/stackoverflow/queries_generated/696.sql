WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.Score,
        PS.CommentCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM 
        PostStatistics PS
    WHERE 
        PS.Score > 10
)
SELECT 
    R.PostId,
    R.Title,
    R.ViewCount,
    R.Score,
    R.CommentCount,
    U.DisplayName,
    COALESCE(UV.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(UV.UpVotes, 0) AS UserUpVotes,
    COALESCE(UV.DownVotes, 0) AS UserDownVotes
FROM 
    RankedPosts R
LEFT JOIN 
    UserVoteStats UV ON R.PostId IN (
        SELECT PostId FROM Votes WHERE UserId = UV.UserId
    )
OUTER APPLY (
    SELECT TOP 1 
        U.DisplayName 
    FROM 
        Users U 
    WHERE 
        U.Id = (
            SELECT TOP 1 P.OwnerUserId 
            FROM Posts P 
            WHERE P.Id = R.PostId
        )
) AS Owner
WHERE 
    R.Rank <= 50
ORDER BY 
    R.Rank;
