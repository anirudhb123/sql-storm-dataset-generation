WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalBounty, 
        UpVotes, 
        DownVotes, 
        PostCount, 
        ReputationRank
    FROM 
        UserScore 
    WHERE 
        Reputation > 0
    ORDER BY 
        Reputation DESC
    LIMIT 10
),
TagCounts AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalBounty,
    TU.UpVotes,
    TU.DownVotes,
    TU.PostCount,
    TG.TagName,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.OwnerDisplayName
FROM 
    TopUsers TU
CROSS JOIN 
    TagCounts TG
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.PostRank <= 2
ORDER BY 
    TU.Reputation DESC, 
    TG.PostCount DESC, 
    RP.CreationDate DESC

