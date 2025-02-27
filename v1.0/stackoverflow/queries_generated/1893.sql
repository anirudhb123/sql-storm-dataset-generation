WITH UserReputation AS (
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
        P.CreationDate,
        P.OwnerUserId,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, PT.Name
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(P.Tags, '<>')) AS TagName
    FROM 
        Posts P
    WHERE 
        P.ViewCount > 1000
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    PVS.UpVotes,
    PVS.DownVotes,
    CASE 
        WHEN PVS.UpVotes IS NULL THEN 'No Votes'
        ELSE CASE 
            WHEN PVS.UpVotes > PVS.DownVotes THEN 'More UpVotes'
            ELSE 'More DownVotes'
        END 
    END AS VoteComparison,
    COALESCE(PT.Tags, 'No Tags') AS Tags
FROM 
    UserReputation U
JOIN 
    RecentPosts RP ON U.UserId = RP.OwnerUserId
LEFT JOIN 
    PostVoteStats PVS ON RP.PostId = PVS.PostId
LEFT JOIN 
    (SELECT DISTINCT TagName FROM PopularTags) PT ON PT.TagName = ANY(STRING_TO_ARRAY(RP.Tags, '<>'))
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    RP.Score DESC, U.Reputation DESC
LIMIT 100;
