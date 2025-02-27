WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND P.Score > 0
),
PostStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount 
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON C.PostId = RP.PostId 
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        PS.CommentCount,
        RANK() OVER(ORDER BY RP.Score DESC, RP.ViewCount DESC, RP.CreationDate ASC) AS OverallRank
    FROM 
        RankedPosts RP
    JOIN 
        PostStatistics PS ON RP.PostId = PS.PostId
    WHERE 
        RP.Rank <= 5
)
SELECT 
    TP.*,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TP.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TP.PostId AND V.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(T.TagName, ', ') FROM Posts P JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%' WHERE P.Id = TP.PostId) AS Tags
FROM 
    TopPosts TP
ORDER BY 
    TP.OverallRank
LIMIT 10;
