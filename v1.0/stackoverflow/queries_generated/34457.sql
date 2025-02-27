WITH RecursivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Questions Only
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        RP.Level + 1 AS Level
    FROM 
        Posts P
    INNER JOIN 
        RecursivePosts RP ON P.ParentId = RP.Id
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        R.Level AS PostLevel,
        COUNT(P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        RecursivePosts R ON U.Id = R.OwnerUserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName, R.Level
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(Reputation) AS TotalReputation,
        SUM(TotalPosts) AS TotalPosts
    FROM 
        UserReputation
    GROUP BY 
        UserId, DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        P.Title
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate > NOW() - INTERVAL '1 year' -- Only considering recent changes
)
SELECT 
    U.DisplayName,
    U.TotalReputation,
    U.TotalPosts,
    COALESCE(PHD.PostTitleCount, 0) AS RecentEditCount,
    SUM(CASE WHEN P.Score IS NULL THEN 0 ELSE P.Score END) AS TotalScore,
    AVG(P.ViewCount) AS AvgViewCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers U
LEFT JOIN 
    PostHistoryDetails PHD ON U.UserId = PHD.PostId
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            T.TagName
        FROM 
            unnest(string_to_array(P.Tags, ',')) AS T(TagName)
    ) AS T ON TRUE
WHERE 
    U.TotalPosts > 0
GROUP BY 
    U.UserId, U.DisplayName
ORDER BY 
    U.TotalReputation DESC
LIMIT 50;
