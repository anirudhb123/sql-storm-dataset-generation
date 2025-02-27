WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.Reputation
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM 
        RecentPosts
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerUserId,
        RP.Score,
        RP.ViewCount,
        RP.OwnerReputation,
        RP.UpVotes,
        RP.DownVotes,
        COALESCE(PH.Note, 'No Recent Edits') AS LastEditComment
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId 
        AND PH.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = RP.PostId)
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.OwnerReputation,
    PD.Score,
    PD.ViewCount,
    PD.UpVotes,
    PD.DownVotes,
    CASE 
        WHEN PD.Score > 10 THEN 'Highly Popular'
        WHEN PD.Score BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS Popularity,
    CASE 
        WHEN PD.LastEditComment IS NULL THEN 'Unedited'
        ELSE PD.LastEditComment
    END AS Status
FROM 
    PostDetails PD
WHERE 
    PD.OwnerReputation > 100
ORDER BY 
    PD.PostRank
FETCH FIRST 10 ROWS ONLY;
