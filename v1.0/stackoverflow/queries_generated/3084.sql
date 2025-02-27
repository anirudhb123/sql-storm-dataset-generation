WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.LastActivityDate,
        COUNT(C.ID) AS CommentCount,
        SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3) AS Score -- Upvotes - Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        U.DisplayName AS AuthorDisplayName,
        RP.Score,
        RP.CommentCount,
        UR.ReputationRank,
        COALESCE(PH.Comment, 'No History') AS LastHistoryAction
    FROM 
        RecentPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    JOIN 
        UserRankings UR ON U.Id = UR.UserId
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId AND PH.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = RP.PostId
        )
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.AuthorDisplayName,
    PD.Score,
    PD.CommentCount,
    PD.ReputationRank,
    PD.LastHistoryAction
FROM 
    PostDetails PD
WHERE 
    PD.Score > 0
ORDER BY 
    PD.ReputationRank, PD.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
