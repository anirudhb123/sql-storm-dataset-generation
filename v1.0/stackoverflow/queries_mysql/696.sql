
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
        U.Id, U.DisplayName
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
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.Score,
        PS.CommentCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostStatistics PS, (SELECT @rownum := 0) r
    WHERE 
        PS.Score > 10
    ORDER BY 
        PS.Score DESC, PS.ViewCount DESC
)
SELECT 
    R.PostId,
    R.Title,
    R.ViewCount,
    R.Score,
    R.CommentCount,
    Owner.DisplayName,
    COALESCE(UV.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(UV.UpVotes, 0) AS UserUpVotes,
    COALESCE(UV.DownVotes, 0) AS UserDownVotes
FROM 
    RankedPosts R
LEFT JOIN 
    UserVoteStats UV ON R.PostId IN (
        SELECT PostId FROM Votes WHERE UserId = UV.UserId
    )
LEFT JOIN (
    SELECT 
        U.DisplayName, 
        P.Id AS PostId 
    FROM 
        Users U 
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
) AS Owner ON R.PostId = Owner.PostId
WHERE 
    R.Rank <= 50
ORDER BY 
    R.Rank;
