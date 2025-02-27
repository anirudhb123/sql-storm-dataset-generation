WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(P.Tags, '>') AS TagArray 
        ON TRUE
    LEFT JOIN 
        Tags T ON TRIM(BOTH '<>' FROM TagArray) = T.TagName
    WHERE 
        P.PostTypeId = 1  -- Filtering for questions only
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.Score, P.ViewCount, P.OwnerUserId
),

FilteredRanks AS (
    SELECT 
        *,
        CASE 
            WHEN OwnerPostRank = 1 THEN 'Latest Question'
            WHEN OwnerPostRank <= 5 THEN 'Recent Questions'
            ELSE 'Older Questions'
        END AS QuestionCategory
    FROM 
        RankedPosts
)

SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.OwnerDisplayName,
    FR.Score,
    FR.ViewCount,
    FR.CommentCount,
    FR.Tags,
    FR.QuestionCategory
FROM 
    FilteredRanks FR
WHERE 
    FR.QuestionCategory = 'Latest Question'
ORDER BY 
    FR.CreationDate DESC;
