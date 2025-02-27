WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Author,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 -- Upvote
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '><')) AS Tag(TagName) ON TRUE
    WHERE 
        P.PostTypeId = 1 -- Questions
    GROUP BY 
        P.Id, U.DisplayName
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        JSONB_AGG(
            JSONB_BUILD_OBJECT(
                'PostHistoryType', PHT.Name,
                'UserDisplayName', PH.UserDisplayName,
                'Comment', PH.Comment,
                'CreationDate', PH.CreationDate
            )
        ) AS History
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.Author,
    RP.CommentCount,
    RP.VoteCount,
    RP.Tags,
    PHD.LastEditDate,
    PHD.History
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryData PHD ON RP.PostId = PHD.PostId
ORDER BY 
    RP.CreationDate DESC
LIMIT 50;
