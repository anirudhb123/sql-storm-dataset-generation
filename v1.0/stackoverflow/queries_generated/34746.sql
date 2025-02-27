WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only questions
    
    UNION ALL 
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        RP.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RP ON P.ParentId = RP.PostId
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalPostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RankedPosts AS (
    SELECT 
        P.*,
        V.TotalVotes,
        V.UpVotes,
        V.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        VoteCounts V ON P.Id = V.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalBadges,
    U.TotalPosts,
    U.TotalPostScore,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS QuestionCreationDate,
    RP.Level AS QuestionLevel,
    R.TotalVotes,
    R.UpVotes,
    R.DownVotes
FROM 
    UserStatistics U
JOIN 
    RankedPosts R ON U.UserId = R.OwnerUserId
JOIN 
    RecursivePostHierarchy RP ON RP.PostId = R.Id
WHERE 
    RP.Level > 0 
    AND (R.UpVotes - R.DownVotes) > 5  -- More positive feedback
ORDER BY 
    U.TotalPostScore DESC, 
    RP.Title;
