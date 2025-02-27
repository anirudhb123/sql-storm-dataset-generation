WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        STRING_AGG(T.TagName, ', ') AS CombinedTags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    CROSS JOIN 
        LATERAL string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><') AS T(TagName)
    GROUP BY 
        P.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        OwnerDisplayName, 
        CreationDate, 
        ViewCount, 
        Score, 
        CombinedTags,
        RANK() OVER (PARTITION BY CombinedTags ORDER BY CreationDate DESC) AS Rank
    FROM 
        TaggedPosts
)
SELECT 
    RP.Title,
    RP.OwnerDisplayName,
    RP.ViewCount,
    RP.Score,
    RP.CombinedTags,
    COUNT(C.Id) AS CommentCount,
    MAX(B.Date) AS LastBadgeAwarded
FROM 
    RecentPosts RP
LEFT JOIN 
    Comments C ON RP.PostId = C.PostId
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
WHERE 
    RP.Rank = 1
GROUP BY 
    RP.Title, RP.OwnerDisplayName, RP.ViewCount, RP.Score, RP.CombinedTags
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC
LIMIT 10;
