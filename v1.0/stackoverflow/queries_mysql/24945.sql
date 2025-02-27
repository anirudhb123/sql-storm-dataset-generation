
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
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts P
    JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
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
        TP.PostId, GROUP_CONCAT(TP.Tag SEPARATOR ', ') AS PosterGroup 
    FROM 
        TaggedPosts TP
    GROUP BY 
        TP.PostId
) PG ON PG.PostId = RP.PostId
WHERE 
    RP.Rank <= 10
ORDER BY 
    NetVotes DESC, RP.CreationDate DESC;
