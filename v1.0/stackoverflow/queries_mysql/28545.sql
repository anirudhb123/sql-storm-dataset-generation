
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Author,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.ViewCount
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        ViewCount,
        CommentCount,
        UpvoteCount,
        DownvoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Author,
    FP.CreationDate,
    FP.ViewCount,
    FP.CommentCount,
    FP.UpvoteCount,
    FP.DownvoteCount,
    CASE 
        WHEN FP.UpvoteCount > FP.DownvoteCount THEN 'Popular'
        WHEN FP.UpvoteCount < FP.DownvoteCount THEN 'Unpopular'
        ELSE 'Neutral'
    END AS PopularityStatus,
    GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName ASC SEPARATOR ', ') AS AssociatedTags
FROM 
    FilteredPosts FP
LEFT JOIN 
    Posts P ON FP.PostId = P.Id
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1) AS TagName
     FROM Posts P
     INNER JOIN (SELECT @row := @row + 1 AS n FROM 
                  (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) numbers,
                  (SELECT @row:=0) r) numbers 
     ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1) T ON TRUE
GROUP BY 
    FP.PostId, FP.Title, FP.Author, FP.CreationDate, FP.ViewCount, FP.CommentCount, FP.UpvoteCount, FP.DownvoteCount
ORDER BY 
    FP.CreationDate DESC
LIMIT 50;
