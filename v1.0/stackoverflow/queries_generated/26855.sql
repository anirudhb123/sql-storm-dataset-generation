WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Author,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><'))::varchar[]) AS TagName 
         FROM 
             Posts
         WHERE 
             PostTypeId = 1) T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        Author,
        CommentCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.Author,
    TP.CommentCount,
    TP.Tags,
    COALESCE(BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts TP
LEFT JOIN 
    (SELECT 
        UserId,
        COUNT(*) AS BadgeCount 
     FROM 
        Badges 
     GROUP BY 
        UserId) B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE 
    TP.Rank <= 10
ORDER BY 
    TP.Rank;
