WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND P.ViewCount > 100
),
TopPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.ViewCount, 
        RP.Score,
        RP.PostRank,
        CASE 
            WHEN RP.Upvotes > RP.Downvotes THEN 'Positive'
            WHEN RP.Upvotes < RP.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5
),
PostWithHistory AS (
    SELECT 
        T.Title,
        H.PostHistoryTypeId,
        H.CreationDate AS HistoryDate,
        H.UserDisplayName,
        H.Comment,
        H.Text
    FROM 
        TopPosts T
    LEFT JOIN 
        PostHistory H ON T.PostId = H.PostId
    WHERE 
        H.CreationDate BETWEEN T.CreationDate AND CURRENT_TIMESTAMP
)
SELECT 
    PWH.Title,
    PWH.PostHistoryTypeId,
    COALESCE(PWH.HistoryDate, 'No History') AS HistoryDate,
    COALESCE(PWH.UserDisplayName, 'Unknown User') AS User,
    COALESCE(PWH.Comment, 'No Comment') AS Comment,
    COALESCE(PWH.Text, 'No Changes') AS Changes,
    TP.VoteSentiment
FROM 
    PostWithHistory PWH
JOIN 
    TopPosts TP ON PWH.Title = TP.Title
ORDER BY 
    TP.Score DESC,
    PWH.HistoryDate DESC NULLS LAST;

-- Further elaborating potential corner cases
SELECT 
    DISTINCT T.TagName,
    COALESCE(COUNT(DISTINCT P.Id), 0) AS RelatedPostsCount,
    SUM(CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 
            ELSE 0 
        END) AS CloseReopenCount,
    STRING_AGG(CASE 
                   WHEN B.Class = 1 THEN 'Gold' 
                   WHEN B.Class = 2 THEN 'Silver' 
                   WHEN B.Class = 3 THEN 'Bronze' 
                   ELSE 'Unknown' 
               END, ', ') AS BadgeClasses
FROM 
    Tags T
LEFT JOIN 
    Posts P ON T.Id = ANY(string_to_array(P.Tags, '><')::int[])
LEFT JOIN 
    Badges B ON P.OwnerUserId = B.UserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    T.Count > 10
GROUP BY 
    T.TagName
HAVING 
    COUNT(DISTINCT P.Id) > 0 OR 
    SUM(CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 
            ELSE 0 
        END) > 0
ORDER BY 
    RelatedPostsCount DESC, 
    TagName;
