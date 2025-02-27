
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.Score,
        P.ViewCount,
        @row_number := IF(@current_post_type = P.PostTypeId, @row_number + 1, 1) AS rn,
        @current_post_type := P.PostTypeId,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id,
        (SELECT @row_number := 0, @current_post_type := 0) AS vars
    WHERE 
        P.CreationDate BETWEEN '2023-01-01' AND '2023-10-01'
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
PostWithComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentsCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalResult AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerName,
        RP.Score,
        RP.ViewCount,
        RP.Upvotes,
        RP.Downvotes,
        COALESCE(PWC.CommentsCount, 0) AS CommentsCount,
        (SELECT GROUP_CONCAT(TagName SEPARATOR ', ') FROM PopularTags WHERE PostsCount > 5) AS PopularTags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostWithComments PWC ON RP.PostId = PWC.PostId
    WHERE 
        RP.rn <= 5
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.OwnerName,
    FR.Score,
    FR.ViewCount,
    FR.Upvotes,
    FR.Downvotes,
    FR.CommentsCount,
    FR.PopularTags
FROM 
    FinalResult FR
ORDER BY 
    FR.Score DESC, FR.ViewCount DESC;
