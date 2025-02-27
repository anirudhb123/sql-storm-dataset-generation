WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        0 AS Level
    FROM 
        Users AS U
    WHERE 
        U.Reputation >= 1000
    
    UNION ALL
    
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        UR.Level + 1
    FROM 
        Users AS U
    INNER JOIN 
        UserReputation AS UR ON U.Reputation < UR.Reputation
    WHERE 
        UR.Level < 5
), PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2021-01-01' AND P.CreationDate < '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.CreationDate
), RankedPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.CommentCount,
        PA.UpVotes,
        PA.DownVotes,
        RANK() OVER (ORDER BY PA.UpVotes - PA.DownVotes DESC) AS PostRank
    FROM 
        PostAnalytics PA
)

SELECT 
    UR.DisplayName,
    UR.Reputation,
    P.Title,
    P.CreationDate,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    CASE 
        WHEN P.CommentCount > 10 THEN 'Highly Engaged'
        WHEN P.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    UserReputation UR
JOIN 
    RankedPosts P ON UR.Id = P.PostId
WHERE 
    P.PostRank <= 20 
    AND UR.Reputation BETWEEN 1000 AND 5000
ORDER BY 
    UR.Reputation DESC, P.UpVotes DESC;
