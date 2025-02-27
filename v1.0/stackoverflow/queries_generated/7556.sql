WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        RP.*
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 10
),
PostComments AS (
    SELECT 
        PC.PostId,
        COUNT(PC.Id) AS CommentCount
    FROM 
        Comments PC
    WHERE 
        PC.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PC.PostId
),
PostTags AS (
    SELECT 
        PT.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts PT
    JOIN 
        UNNEST(string_to_array(substring(PT.Tags, 2, length(PT.Tags)-2), '><')) AS TagName ON T.TagName = TagName
    GROUP BY 
        PT.Id
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.CreationDate,
    TP.OwnerDisplayName,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PT.Tags, 'No Tags') AS Tags
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostTags PT ON TP.PostId = PT.PostId
ORDER BY 
    TP.Score DESC;
