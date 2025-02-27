WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(*) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(*) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount,
        MAX(P.LastActivityDate) AS LastActive,
        P.CreationDate,
        COALESCE(P.ClosedDate, P.LastActivityDate) AS FinalDate,
        (EXTRACT(EPOCH FROM COALESCE(P.ClosedDate, P.LastActivityDate) - P.CreationDate) / 3600) AS DurationInHours
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
PostDetails AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        PS.LastActive,
        PS.DurationInHours,
        UR.ReputationRank
    FROM 
        PostStatistics PS
    LEFT JOIN 
        UserReputation UR ON PS.OwnerUserId = UR.UserId
),
PostWithTags AS (
    SELECT 
        PD.*,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        PostDetails PD
    LEFT JOIN 
        Posts P ON PD.PostId = P.Id
    LEFT JOIN 
        Tags T ON T.Id IN (SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '>'))::int)
    GROUP BY 
        PD.PostId
)
SELECT 
    PWT.PostId,
    PWT.OwnerUserId,
    PWT.CommentCount,
    PWT.UpVoteCount,
    PWT.DownVoteCount,
    PWT.LastActive,
    PWT.DurationInHours,
    PWT.ReputationRank,
    PWT.Tags,
    CASE 
        WHEN PWT.DurationInHours > 24 THEN 'Long' 
        ELSE 'Short' 
    END AS DurationCategory,
    CASE 
        WHEN PWT.UpVoteCount > PWT.DownVoteCount THEN 'Positive'
        WHEN PWT.UpVoteCount < PWT.DownVoteCount THEN 'Negative'
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    PostWithTags PWT
WHERE 
    PWT.ReputationRank IS NOT NULL
ORDER BY 
    PWT.ReputationRank, PWT.CommentCount DESC;
