
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS AuthorName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.AuthorName,
        RP.CommentCount,
        RP.AnswerCount,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Posts P ON RP.PostId = P.Id
    LEFT JOIN 
        (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', n.n), ',', -1)) AS TagName 
         FROM Posts P CROSS JOIN 
         (SELECT @row := @row + 1 AS n FROM 
          (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
           SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
           SELECT 9 UNION ALL SELECT 10) AS n, (SELECT @row := 0) r) n 
          WHERE n.n <= LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, ',', '')) + 1) AS TagArray ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagArray.TagName
    WHERE 
        RP.UserPostRank <= 5  
    GROUP BY 
        RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.AuthorName, RP.CommentCount, RP.AnswerCount
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.CreationDate,
    FP.AuthorName,
    FP.CommentCount,
    FP.AnswerCount,
    FP.Tags,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    FilteredPosts FP
LEFT JOIN 
    PostHistory PH ON FP.PostId = PH.PostId 
                  AND PH.PostHistoryTypeId IN (4, 5) 
WHERE 
    PH.CreationDate IS NOT NULL
ORDER BY 
    FP.CreationDate DESC;
