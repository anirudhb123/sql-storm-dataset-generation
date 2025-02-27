WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Author,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY T.TagName ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        Tags T ON T.Id = ANY (string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' AND
        P.ViewCount > 100
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.Author,
        RP.ViewCount,
        RP.Score,
        RP.PostType,
        RP.Rank
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Body,
    TP.CreationDate,
    TP.Author,
    TP.ViewCount,
    TP.Score,
    TP.PostType,
    COALESCE(CG.CommentCount, 0) AS CommentCount,
    COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts TP
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) CG ON TP.PostId = CG.PostId
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) BadgeCount ON TP.Author = BadgeCount.UserId
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;
