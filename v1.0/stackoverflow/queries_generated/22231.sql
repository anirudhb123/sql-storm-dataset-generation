WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RN,
        ARRAY_AGG DISTINCT T.TagName FILTER (WHERE T.TagName IS NOT NULL) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        LATERAL string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><') AS TagName ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagName
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserVoteActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        HT.Name AS HistoryType,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
    WHERE 
        PH.CreationDate BETWEEN CURRENT_TIMESTAMP - INTERVAL '60 days' AND CURRENT_TIMESTAMP
    GROUP BY 
        PH.PostId, HT.Name
    HAVING 
        COUNT(PH.Id) > 5
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    R.Tags,
    UA.UserId,
    UA.DisplayName,
    UA.VoteCount,
    UA.Upvotes,
    UA.Downvotes,
    PH.HistoryType,
    PH.HistoryCount,
    CASE 
        WHEN UA.VoteCount IS NULL THEN 'No Votes'
        ELSE 'Votes Recorded'
    END AS VoteStatus,
    CASE 
        WHEN RP.ViewCount IS NULL THEN 'Unviewed'
        ELSE 'Viewed'
    END AS ViewStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVoteActivities UA ON RP.PostId = UA.UserId
LEFT JOIN 
    PostHistoryDetails PH ON RP.PostId = PH.PostId
WHERE 
    (RP.Score > 10 OR RP.ViewCount > 100) 
    AND RP.RN <= 5
ORDER BY 
    RP.CreationDate DESC,
    UA.VoteCount DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
