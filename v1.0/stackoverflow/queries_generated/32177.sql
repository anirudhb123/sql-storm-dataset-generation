WITH RecursivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        0 AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.CreationDate,
        P2.OwnerUserId,
        RP.Depth + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePosts RP ON P2.ParentId = RP.Id
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
VoteAnalysis AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    RP.Id AS PostId,
    RP.Title,
    RP.CreationDate,
    UR.DisplayName AS Owner,
    UR.Reputation AS OwnerReputation,
    CAST(RP.Depth AS varchar) AS PostDepth,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.AverageScore,
    VA.Upvotes,
    VA.Downvotes,
    VA.TotalVotes
FROM 
    RecursivePosts RP
INNER JOIN 
    UserReputation UR ON RP.OwnerUserId = UR.UserId
LEFT JOIN 
    TagStatistics TS ON TS.PostCount > 0
LEFT JOIN 
    VoteAnalysis VA ON VA.PostId = RP.Id
WHERE 
    UR.Reputation > 1000  -- Filtering users with high reputation
ORDER BY 
    RP.CreationDate DESC,
    Upvotes DESC,
    Downvotes ASC;
