WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

CloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CR.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON PH.Comment::integer = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),

CombinedData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.UpVoteCount,
        RP.DownVoteCount,
        COALESCE(CR.CloseReasonNames, 'Not Closed') AS CloseReason,
        CASE 
            WHEN RP.ViewCount > 1000 THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity,
        (COALESCE(RP.UpVoteCount, 0) - COALESCE(RP.DownVoteCount, 0)) AS VoteBalance
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CloseReasons CR ON RP.PostId = CR.PostId
)

SELECT 
    CD.PostId,
    CD.Title,
    CD.CreationDate,
    CD.Score,
    CD.ViewCount,
    CD.UpVoteCount,
    CD.DownVoteCount,
    CD.CloseReason,
    CD.Popularity,
    CD.VoteBalance
FROM 
    CombinedData CD
WHERE 
    CD.Rank <= 5 OR CD.CloseReason != 'Not Closed'
ORDER BY 
    CD.VoteBalance DESC,
    CD.Score DESC;

-- Adding two eccentric constructs using NULL logic and a set operator 
SELECT 
    T.TagName,
    COUNT(*) AS RelatedPostsCount
FROM 
    Tags T
LEFT JOIN 
    Posts P ON POSITION('{' || T.TagName || '}' IN P.Tags) > 0
WHERE 
    T.IsModeratorOnly IS NULL -- Curious usage of NULL directly as a predicate
GROUP BY 
    T.TagName
UNION ALL
SELECT 
    'No Tags' AS TagName,
    COUNT(*) 
FROM 
    Posts P 
WHERE 
    P.Tags IS NULL;
