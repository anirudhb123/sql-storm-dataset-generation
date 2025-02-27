WITH RECURSIVE TopTags AS (
    SELECT 
        T.Id, 
        T.TagName, 
        T.Count,
        0 AS Level
    FROM 
        Tags T
    WHERE 
        T.Count > 1000
  
    UNION ALL
  
    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        Level + 1
    FROM 
        Tags T
    INNER JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    INNER JOIN TopTags TT ON TT.Count < T.Count
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        L.Name AS LinkTypeName,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostLinks PL ON PL.PostId = P.Id
    LEFT JOIN 
        LinkTypes L ON PL.LinkTypeId = L.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS HistoryType,
        PH.UserDisplayName,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RowNum
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.OwnerDisplayName,
    PD.CommentCount,
    PD.LinkTypeName,
    PD.UpvoteCount,
    (SELECT STRING_AGG(TT.TagName, ', ') 
     FROM TopTags TT
     INNER JOIN Posts P2 ON P2.Tags LIKE '%' || TT.TagName || '%'
     WHERE P2.Id = PD.PostId) AS TopTags,
    (SELECT COUNT(*) 
     FROM RecentPostHistory RPH 
     WHERE RPH.PostId = PD.PostId AND RPH.RowNum = 1 AND RPH.HistoryType = 'Post Closed') AS RecentClosed,
    COALESCE(RPH.UserDisplayName, '(No history)') AS LastEditor
FROM 
    PostDetails PD
LEFT JOIN 
    RecentPostHistory RPH ON RPH.PostId = PD.PostId
WHERE 
    PD.ViewCount > 50
ORDER BY 
    PD.Score DESC, 
    PD.CreationDate DESC
LIMIT 100;
