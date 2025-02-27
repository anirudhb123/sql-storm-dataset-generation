WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.VoteCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TagsArray AS (
    SELECT 
        PostId,
        string_to_array(substring(Tags, 2, length(Tags) - 2), '><') AS TagsList
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
),
UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        ARRAY_AGG(DISTINCT T.TagName) AS UserTags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        TagsArray TA ON P.Id = TA.PostId
    JOIN 
        UNNEST(TA.TagsList) AS T(TagName)
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.OwnerReputation,
    UT.UserTags,
    COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
    COUNT(V.Id) AS VoteCount
FROM 
    RankedPosts RP
LEFT JOIN 
    Comments C ON RP.PostId = C.PostId
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    Votes V ON RP.PostId = V.PostId
LEFT JOIN 
    UserTags UT ON RP.OwnerUserId = UT.UserId
WHERE 
    RP.RankPerUser <= 5
GROUP BY 
    RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.Score, RP.ViewCount, 
    RP.OwnerDisplayName, RP.OwnerReputation, UT.UserTags
ORDER BY 
    RP.CreationDate DESC;
