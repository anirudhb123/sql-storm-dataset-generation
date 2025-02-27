
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
        P.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
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
    COALESCE((SELECT STRING_AGG(TG.TagName, ', ') 
              FROM Tags TG 
              JOIN (SELECT value AS TagName FROM STRING_SPLIT(P.Tags, ',')) AS SubTags ON SubTags.TagName = TG.TagName 
              WHERE P.Id = T.PostId), '') AS Tags
FROM 
    TopPosts T
JOIN 
    Posts P ON T.PostId = P.Id
GROUP BY 
    T.Title, T.OwnerDisplayName, T.CreationDate, T.Score, T.UpVoteCount, T.DownVoteCount
ORDER BY 
    T.Score DESC, T.CreationDate DESC;
