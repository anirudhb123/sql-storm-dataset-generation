
WITH UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),

RecentEdits AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        @row_number := IF(@prev_post_id = PH.PostId, @row_number + 1, 1) AS EditRank,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory PH, (SELECT @row_number := 0, @prev_post_id := NULL) AS vars
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
    ORDER BY 
        PH.PostId, PH.CreationDate DESC
),

TopContributors AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UPC.PostCount,
        COUNT(RE.PostId) AS RecentEditCount
    FROM 
        Users U
    JOIN 
        UserPostCount UPC ON U.Id = UPC.UserId
    LEFT JOIN 
        RecentEdits RE ON U.Id = RE.UserId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, UPC.PostCount
    HAVING 
        COUNT(RE.PostId) > 5 
),

MostViewedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        @rank := @rank + 1 AS ViewRank
    FROM 
        Posts P, (SELECT @rank := 0) AS vars
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH) 
    ORDER BY 
        P.ViewCount DESC
)

SELECT 
    U.DisplayName AS Contributor,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.RecentEditCount AS RecentEdits,
    P.Title AS MostViewedPost,
    P.ViewCount
FROM 
    TopContributors U
LEFT JOIN 
    MostViewedPosts P ON U.PostCount > 0
WHERE 
    P.ViewRank <= 10 
ORDER BY 
    U.Reputation DESC, TotalPosts DESC
LIMIT 50;
