WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        CAST(U.Reputation AS bigint) AS TotalReputation,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000  -- Base level for users with reputation > 1000

    UNION ALL

    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        T.TotalReputation + CAST(U.Reputation AS bigint) AS TotalReputation,
        T.Level + 1
    FROM 
        Users U
        JOIN UserReputation T ON U.Reputation > T.TotalReputation
)
, TagsWithPosts AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
        LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id
)
, UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
        LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(TW.PostCount, 0) AS TagPostCount,
    UPS.PostCount AS UserPostCount,
    UPS.TotalViews,
    UPS.TotalScore,
    ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY UPS.TotalScore DESC) AS Ranking
FROM 
    Users U
    LEFT JOIN TagsWithPosts TW ON TW.TagId IN (SELECT unnest(string_to_array(P.Tags, '>'))::int FROM Posts P WHERE P.OwnerUserId = U.Id)
    JOIN UserPostStats UPS ON UPS.UserId = U.Id
WHERE 
    U.Reputation >= (
        SELECT AVG(Reputation) FROM Users
    )
ORDER BY 
    U.Reputation DESC, 
    UPS.TotalViews DESC
LIMIT 100;

-- Additional checks for closed posts
SELECT 
    P.Title,
    P.ViewCount,
    PH.CreationDate AS HistoryChangeDate,
    PH.Comment AS ClosureReason
FROM 
    Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.PostHistoryTypeId = 10 -- Posts that were closed
    AND P.ClosedDate IS NOT NULL
ORDER BY 
    PH.CreationDate DESC;
