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
RecentPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.OwnerDisplayName,
        PH.CreationDate AS HistoryDate,
        PH.PostHistoryTypeId,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY RP.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.OwnerDisplayName,
    COALESCE(PH.Comment, 'No comment') AS LatestComment,
    PH.HistoryDate,
    CASE 
        WHEN RP.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3) AS DownVotes,
    MAX(CASE 
        WHEN PH.PostHistoryTypeId IN (10, 11) THEN PH.CreationDate
        END) AS ClosureDate,
    COUNT(DISTINCT C.Id) AS CommentCount
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentPosts PH ON RP.PostId = PH.PostId AND PH.HistoryRank = 1
LEFT JOIN 
    Comments C ON C.PostId = RP.PostId
WHERE 
    RP.Rank <= 5
GROUP BY 
    RP.PostId, RP.Title, RP.Score, RP.OwnerDisplayName, PH.Comment, PH.HistoryDate, RP.Rank
ORDER BY 
    RP.Score DESC;
