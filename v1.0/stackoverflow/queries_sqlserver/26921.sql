
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE PostTypeId = 1  
    GROUP BY value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM TagCounts
    ORDER BY PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        Score
    FROM Posts
    WHERE CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
    ORDER BY CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(ISNULL(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId 
    GROUP BY U.Id, U.DisplayName, U.Reputation
)
SELECT 
    T.TagName,
    T.PostCount,
    R.Id AS RecentPostId,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.ViewCount AS RecentPostViews,
    R.OwnerDisplayName AS RecentPostOwner,
    R.Score AS RecentPostScore,
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.TotalPosts AS UserTotalPosts,
    U.TotalScore AS UserTotalScore
FROM TopTags T
LEFT JOIN RecentPosts R ON 1=1  
LEFT JOIN UserReputation U ON R.OwnerDisplayName = U.DisplayName
ORDER BY T.PostCount DESC, R.CreationDate DESC, U.Reputation DESC;
