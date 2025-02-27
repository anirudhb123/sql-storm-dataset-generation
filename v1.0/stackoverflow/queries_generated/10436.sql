-- Performance benchmarking query example for the Stack Overflow schema
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        MAX(P.LastActivityDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Filter for the last year
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(P.Views) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.CommentCount,
    PS.VoteCount,
    PS.AnswerCount,
    PS.LastActivityDate,
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.TotalViews
FROM 
    PostStats PS
JOIN 
    Users US ON US.Id = PS.PostOwnerUserId
ORDER BY 
    PS.LastActivityDate DESC
LIMIT 100; -- Limit to the top 100 posts based on last activity date
