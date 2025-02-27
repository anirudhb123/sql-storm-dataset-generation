
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(P.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(P.TotalComments, 0) AS TotalComments,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        (SELECT 
            OwnerUserId,
            SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
            SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalComments,
            SUM(ViewCount) AS TotalViews
         FROM 
            Posts 
         GROUP BY 
            OwnerUserId) P ON U.Id = P.OwnerUserId
),

RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        LastEditDate,
        Score,
        OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS RecentPostRank
    FROM 
        Posts 
    WHERE 
        LastEditDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)

SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.CreationDate AS AccountCreationDate,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.Score AS RecentPostScore,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.PostId = R.Id) AS TotalCommentsOnPost,
    (SELECT 
        STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM 
        Posts P 
     JOIN 
        Tags T ON P.Tags LIKE '%' + T.TagName + '%'
     WHERE 
        P.Id = R.Id) AS AssociatedTags
FROM 
    UserActivity UA
LEFT JOIN 
    RecentPosts R ON UA.UserId = R.OwnerUserId
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.Reputation DESC, R.RecentPostRank
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
