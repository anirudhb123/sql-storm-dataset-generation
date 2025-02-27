
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    T.Title,
    T.OwnerDisplayName,
    T.CreationDate,
    T.Score,
    T.UpVoteCount,
    T.DownVoteCount,
    COALESCE((SELECT GROUP_CONCAT(TG.TagName SEPARATOR ', ') 
              FROM Tags TG 
              JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1) AS TagName
                    FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                    WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS SubTags 
              ON SubTags.TagName = TG.TagName 
              WHERE P.Id = T.PostId), '') AS Tags
FROM 
    TopPosts T
JOIN 
    Posts P ON T.PostId = P.Id
ORDER BY 
    T.Score DESC, T.CreationDate DESC;
