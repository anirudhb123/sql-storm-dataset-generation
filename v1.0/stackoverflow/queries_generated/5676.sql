WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(A.Id) AS TotalAnswers,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Author,
    TO_CHAR(TP.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.TotalComments,
    TP.TotalAnswers,
    COALESCE(BadgeCount, 0) AS TotalBadges
FROM 
    TopPosts TP
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;
