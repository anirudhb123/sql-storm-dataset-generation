WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.CreationDate, P.CreationDate) AS MostRecentEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COALESCE(PH.CreationDate, P.CreationDate) DESC) AS EditRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Considering only Questions
),
TagsAggregated AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName ON TRUE
    JOIN 
        Tags T ON T.TagName = TagName
    GROUP BY 
        P.Id
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000 -- Only considering users with reputation greater than 1000
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        PostsCount DESC
    LIMIT 10
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.ViewCount, 
    RP.Score, 
    RP.OwnerDisplayName, 
    RP.MostRecentEditDate,
    TA.TagsList,
    MAU.DisplayName AS MostActiveUser,
    MAU.PostsCount
FROM 
    RankedPosts RP
JOIN 
    TagsAggregated TA ON RP.PostId = TA.PostId
JOIN 
    MostActiveUsers MAU ON 1 = 1 -- Cross join to get the names of active users
WHERE 
    RP.EditRank = 1 -- Only the most recent edit for each user
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC
LIMIT 50;
