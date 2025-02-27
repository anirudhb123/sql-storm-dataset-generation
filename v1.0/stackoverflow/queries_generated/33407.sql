WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
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
    RPH.PostId,
    RPH.Title,
    RPH.CreationDate,
    RPH.Level,
    V.VoteCount,
    V.UpVotes,
    V.DownVotes,
    COALESCE(UR.Reputation, 0) AS Reputation,
    UR.DisplayName AS TopUser,
    CASE 
        WHEN V.UpVotes > V.DownVotes 
        THEN 'Positive' 
        ELSE 
            CASE 
                WHEN V.UpVotes < V.DownVotes 
                THEN 'Negative' 
                ELSE 'Neutral' 
            END 
    END AS VoteSentiment
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    PostVoteSummary V ON RPH.PostId = V.PostId
LEFT JOIN 
    UserReputation UR ON UR.Rank = 1
WHERE 
    RPH.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    RPH.Level, RPH.CreationDate DESC;
