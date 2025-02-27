WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        T.TagName,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        STRING_SPLIT(P.Tags, '>') AS T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, U.DisplayName
),

UserActivity AS (
    SELECT 
        UH.UserId,
        COUNT(U.Id) AS PostsCreated,
        COUNT(C.Id) AS CommentsMade
    FROM 
        Users UH
    LEFT JOIN 
        Posts U ON UH.Id = U.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.PostId
    GROUP BY 
        UH.UserId
)

SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.BadgeNames,
    PD.Title,
    PD.ViewCount,
    PD.Score,
    PD.AnswerCount,
    PD.CommentCount,
    UA.PostsCreated,
    UA.CommentsMade
FROM 
    UserBadges U
JOIN 
    PostDetails PD ON U.UserId = PD.OwnerUserId
JOIN 
    UserActivity UA ON UA.UserId = U.UserId
WHERE 
    U.BadgeCount > 1
    AND PD.ViewCount > 100
ORDER BY 
    UA.PostsCreated DESC, 
    PD.Score DESC;
