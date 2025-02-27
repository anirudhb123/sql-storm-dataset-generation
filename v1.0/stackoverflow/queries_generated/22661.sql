WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CAST(U.CreationDate AS DATE) ORDER BY U.Reputation DESC) AS UserRanking
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),

PopularTags AS (
    SELECT 
        T.Id,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS PopularityRank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName
),

RecentlyEditedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastEditDate,
        HT.UserDisplayName,
        HT.Comment
    FROM 
        Posts P
    JOIN 
        PostHistory HT ON HT.PostId = P.Id AND HT.PostHistoryTypeId IN (4, 5)
    WHERE 
        P.LastEditDate >= NOW() - INTERVAL '7 days'
),

UpvotesByPost AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),

PopularUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    JOIN 
        UpvotesByPost UP ON UP.PostId = U.Id
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)

SELECT 
    R.DisplayName AS UserName,
    R.Reputation AS UserReputation,
    P.Title AS PostTitle,
    P.LastEditDate,
    T.TagName AS PopularTag,
    R.UserRanking,
    HT.Comment AS HistoryComment
FROM 
    RankedUsers R
JOIN 
    RecentlyEditedPosts P ON R.Id = P.OwnerUserId
JOIN 
    PopularTags T ON T.TagName = ANY(string_to_array(P.Tags, ','))
LEFT JOIN 
    PostHistory HT ON HT.PostId = P.PostId
WHERE 
    R.UserRanking <= 5 
    AND (HT.UserDisplayName IS NOT NULL OR P.LastEditDate IS NOT NULL)
ORDER BY 
    R.UserRanking, P.LastEditDate DESC;

-- Edge case inclusion
SELECT 
    U.DisplayName AS UserName,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN P.Tags IS NULL OR P.Tags = '' THEN 'No Tags Available'
        ELSE P.Tags
    END AS TagsStatus
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.LastAccessDate < NOW() - INTERVAL '1 year'
    AND P.ViewCount IS NULL;
