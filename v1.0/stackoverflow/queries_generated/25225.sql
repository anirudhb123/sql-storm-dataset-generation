WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 -- Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.OwnerDisplayName
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(TRIM(SUBSTRING(T.Tags, 2, LEN(T.Tags)-2)), ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        LATERAL string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><') AS T(Tag) ON TRUE
    GROUP BY 
        P.Id
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.OwnerDisplayName,
    PT.Tags,
    RP.AnswerCount,
    RP.CommentCount,
    UBC.BadgeCount,
    RP.CreationDate + INTERVAL '1 month' AS ExpirationDate
FROM 
    RankedPosts RP
LEFT JOIN 
    PostTags PT ON RP.PostId = PT.PostId
LEFT JOIN 
    UserBadgeCounts UBC ON RP.OwnerUserId = UBC.UserId
WHERE 
    RP.AnswerCount > 5 -- Focusing on questions with significant engagement
ORDER BY 
    RP.CreationDate DESC;
