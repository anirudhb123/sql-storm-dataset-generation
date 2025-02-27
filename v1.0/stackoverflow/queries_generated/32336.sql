WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(V.Id) AS VoteCount
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
        COUNT(C.Id) AS TotalComments,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS TotalVotes,
        COUNT(DISTINCT (CASE WHEN PH.PostId IS NOT NULL THEN PH.PostId END)) AS HistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title
),
PostWithUserVotes AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.TotalComments,
        PS.TotalVotes,
        PS.HistoryCount,
        UVC.VoteCount
    FROM 
        PostStatistics PS
    LEFT JOIN 
        UserVoteCounts UVC ON UVC.VoteCount > 0
),
RankedPosts AS (
    SELECT 
        PWV.PostId,
        PWV.Title,
        PWV.TotalComments,
        PWV.TotalVotes,
        PWV.HistoryCount,
        PWV.VoteCount,
        RANK() OVER (ORDER BY PWV.TotalVotes DESC, PWV.TotalComments DESC) AS Rank
    FROM 
        PostWithUserVotes PWV
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.TotalComments,
    RP.TotalVotes,
    RP.HistoryCount,
    RP.VoteCount,
    RP.Rank,
    CASE 
        WHEN RP.VoteCount IS NULL THEN 'No Votes'
        ELSE 'Voted'
    END AS VoteStatus
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Rank;
