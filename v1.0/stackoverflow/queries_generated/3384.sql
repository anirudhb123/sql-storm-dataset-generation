WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Questions
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        PH.PostId, PH.CreationDate, C.Name
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    T.PostId,
    T.Title,
    T.CreationDate,
    T.Score,
    C.CloseReason,
    COALESCE(C.CloseCount, 0) AS TotalClosedPosts
FROM 
    UserScores U
LEFT JOIN 
    TopPosts T ON U.UserId = T.Owner
LEFT JOIN 
    ClosedPosts C ON T.PostId = C.PostId
WHERE 
    U.Rank <= 10 -- Top 10 users by reputation
ORDER BY 
    U.Rank, T.Score DESC
LIMIT 100;
