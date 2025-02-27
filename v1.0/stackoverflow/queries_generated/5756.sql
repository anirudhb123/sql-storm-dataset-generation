WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    T.Title,
    T.ViewCount,
    T.Score,
    T.OwnerDisplayName,
    COALESCE(SUM(B.Class = 1), 0) AS GoldBadges,
    COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
    COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges
FROM 
    TopPosts T
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = T.PostId)
GROUP BY 
    T.PostId, T.Title, T.ViewCount, T.Score, T.OwnerDisplayName
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
