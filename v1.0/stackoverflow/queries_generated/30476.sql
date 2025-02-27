WITH RECURSIVE UserHierarchy AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 5000  -- starting point for high reputation users
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        UH.Level + 1
    FROM 
        Users U
    JOIN 
        UserHierarchy UH ON U.Id = UH.Id + 1  -- arbitrary level mapping for recursion
    WHERE 
        U.Reputation > UH.Reputation  -- only progress to users with higher reputation
),
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  -- count of upvotes
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes   -- count of downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'  -- focus on recent posts
    GROUP BY 
        P.Id
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        PV.VoteCount,
        PV.UpVotes,
        PV.DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostVoteDetails PV ON P.Id = PV.PostId
    WHERE 
        P.PostTypeId = 1  -- focus only on Questions
),

TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation >= (
            SELECT 
                AVG(Reputation) 
            FROM 
                Users 
            WHERE 
                LastAccessDate > NOW() - INTERVAL '1 year'  -- recent activity
        )
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)

SELECT 
    RP.Title, 
    RP.CreationDate, 
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    TU.DisplayName AS TopUser,
    TU.Reputation AS TopUserReputation,
    COALESCE(RP.VoteCount, 0) AS TotalVotes,
    COALESCE(RP.UpVotes, 0) AS TotalUpVotes,
    COALESCE(RP.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN RP.OwnerUserId IS NULL THEN 'Unknown'
        ELSE 'Known User'
    END AS UserStatus
FROM 
    RecentPosts RP
LEFT JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.Id
ORDER BY 
    RP.Score DESC,  -- prioritize by score
    RP.ViewCount DESC;  -- then by view count
