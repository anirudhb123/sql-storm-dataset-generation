WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(P.CreationDate) AS LastActive,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.Upvotes,
    UA.Downvotes,
    UA.LastActive,
    CASE 
        WHEN UA.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    COALESCE(NULLIF(UT.Name, ''), 'No User Type') AS UserType
FROM 
    UserActivity UA
LEFT JOIN 
    (SELECT * FROM (VALUES (1, 'Active'), (2, 'Inactive'), (3, 'Guest')) AS UT(Id, Name)) UT ON UA.Reputation / 100 > UT.Id
WHERE 
    UA.PostCount > 0 
    AND (UA.LastActive >= NOW() - INTERVAL '1 year')
ORDER BY 
    UA.Reputation DESC;

WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Bounty Start and Close
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score
    HAVING 
        SUM(V.BountyAmount) > 0
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.CommentCount,
    RP.TotalBounty
FROM 
    RecentPosts RP
ORDER BY 
    RP.TotalBounty DESC
LIMIT 5;

SELECT 
    P.Id,
    P.Title,
    U.DisplayName AS OwnerName,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate
FROM 
    Posts P
INNER JOIN 
    PostHistory PH ON P.Id = PH.PostId
INNER JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    PH.PostHistoryTypeId IN (10, 11) 
    AND P.AcceptedAnswerId IS NOT NULL
ORDER BY 
    PH.CreationDate DESC;
