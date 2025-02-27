
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN U.Reputation > 1000 THEN 1 ELSE 0 END) AS HighReputationCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        value AS Tag
    FROM 
        Posts P
    CROSS APPLY STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags)-2), '><')
    WHERE 
        P.Tags IS NOT NULL
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    US.TotalBadges,
    (SELECT COALESCE(SUM(UpVotes), 0) - COALESCE(SUM(DownVotes), 0) FROM PostVoteCounts PVC WHERE PVC.PostId = RP.PostId) AS NetVotes,
    PG.PosterGroup
FROM 
    RankedPosts RP
JOIN 
    UserStats US ON US.UserId = RP.PostId 
LEFT JOIN (
    SELECT 
        TP.PostId, STRING_AGG(TP.Tag, ', ') AS PosterGroup 
    FROM 
        TaggedPosts TP
    GROUP BY 
        TP.PostId
) PG ON PG.PostId = RP.PostId
WHERE 
    RP.Rank <= 10
ORDER BY 
    NetVotes DESC, RP.CreationDate DESC;
