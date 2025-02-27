WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rnk,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerUserId,
        RP.OwnerDisplayName,
        RP.Rnk,
        RP.UpVoteCount,
        RP.DownVoteCount,
        CASE 
            WHEN RP.Score > 10 THEN 'Highly Active'
            WHEN RP.Score BETWEEN 1 AND 10 THEN 'Moderately Active'
            ELSE 'Low Activity'
        END AS ActivityLevel,
        COALESCE(SUM(PH.CreationDate IS NOT NULL), 0) AS EditCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) -- Edits only
    LEFT JOIN 
        STRING_TO_ARRAY(P.Tags, ',') AS T ON T.TagName
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.ViewCount, RP.OwnerUserId, RP.OwnerDisplayName, RP.Rnk
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.OwnerDisplayName,
    PD.ActivityLevel,
    PD.UpVoteCount,
    PD.DownVoteCount,
    PD.EditCount,
    PD.Tags,
    COALESCE(MOST_ACTIVE_USER.DisplayName, 'No Votes') AS MostActiveUser
FROM 
    PostDetails PD
LEFT JOIN 
    (SELECT 
         PostId, 
         U.DisplayName,
         COUNT(*) AS UserVoteCount,
         RANK() OVER (PARTITION BY PostId ORDER BY COUNT(*) DESC) AS UserRank
     FROM 
         Votes V
     LEFT JOIN 
         Users U ON V.UserId = U.Id
     GROUP BY 
         PostId, U.DisplayName
    ) AS MOST_ACTIVE_USER ON PD.PostId = MOST_ACTIVE_USER.PostId AND MOST_ACTIVE_USER.UserRank = 1
WHERE 
    (PD.UpVoteCount > 0 AND PD.DownVoteCount = 0)
    OR PD.ViewCount > 100
ORDER BY 
    PD.Score DESC,
    PD.UpVoteCount DESC;

-- Ensure that the final results handle potential NULL values in User ratings

