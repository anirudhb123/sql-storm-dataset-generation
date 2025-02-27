WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownvotes,
        (COALESCE(SUM(V.VoteTypeId = 2), 0) - COALESCE(SUM(V.VoteTypeId = 3), 0)) AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions only
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerName,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId, U.DisplayName
),
CombinedMetrics AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalUpvotes,
        us.TotalDownvotes,
        us.NetVotes,
        us.PostCount,
        us.BadgeCount,
        pd.PostId,
        pd.Title,
        pd.OwnerName,
        pd.CommentCount,
        pd.PostRank
    FROM 
        UserStats us
    FULL OUTER JOIN 
        PostDetails pd ON us.UserId = pd.OwnerName
    WHERE 
        (us.NetVotes > 0 OR pd.CommentCount > 0)
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalUpvotes,
    TotalDownvotes,
    NetVotes,
    PostCount,
    BadgeCount,
    PostId,
    Title,
    OwnerName,
    CommentCount,
    PostRank,
    CASE 
        WHEN PostRank IS NOT NULL AND PostRank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN Reputation > 1000 THEN 'Veteran User'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserCategory
FROM 
    CombinedMetrics
ORDER BY 
    UserId NULLS LAST, 
    PostRank DESC NULLS LAST;
