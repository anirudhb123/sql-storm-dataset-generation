
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
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
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(PH.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            GROUP_CONCAT(CASE WHEN Comment IS NOT NULL THEN Comment ELSE '' END SEPARATOR ', ') AS CloseReason
        FROM 
            PostHistory PH
        WHERE 
            PH.PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.OwnerDisplayName,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        @row_rank := IF(@prev_owner = PS.OwnerUserId, @row_rank + 1, 1) AS PostRank,
        @prev_owner := PS.OwnerUserId
    FROM 
        PostStats PS, (SELECT @row_rank := 0, @prev_owner := NULL) r
    ORDER BY 
        PS.OwnerUserId, PS.Score DESC
)
SELECT 
    UPC.UserId,
    UPC.TotalVotes,
    UPC.UpVotes,
    UPC.DownVotes,
    RP.OwnerDisplayName,
    RP.PostId,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    CASE 
        WHEN RP.PostRank IS NOT NULL AND RP.PostRank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    UserVoteCounts UPC
LEFT JOIN 
    RankedPosts RP ON UPC.UserId = RP.OwnerUserId
WHERE 
    UPC.TotalVotes > 0
ORDER BY 
    UPC.TotalVotes DESC, 
    RP.Score DESC
LIMIT 50;
