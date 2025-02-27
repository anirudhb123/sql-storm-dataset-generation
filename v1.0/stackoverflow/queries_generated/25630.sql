WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 -- Upvoted
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.VoteCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.RecentPostRank = 1 -- Latest post for each tag
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.Tags,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.CommentCount,
    FP.VoteCount,
    COALESCE(STRING_AGG(DISTINCT B.Name, ', '), 'No badges') AS Badges
FROM 
    FilteredPosts FP
LEFT JOIN 
    Badges B ON B.UserId = (SELECT U.Id FROM Users U WHERE U.DisplayName = FP.OwnerDisplayName)
GROUP BY 
    FP.PostId, FP.Title, FP.Body, FP.Tags, FP.CreationDate, FP.OwnerDisplayName, FP.CommentCount, FP.VoteCount
ORDER BY 
    FP.CreationDate DESC
LIMIT 10;
