WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, U.Reputation
),

PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),

PostHistoryData AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.Comment,
        PH.Text
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Reputation,
    RP.UpVoteCount,
    RP.DownVoteCount,
    CASE 
        WHEN PHD.Comment IS NOT NULL THEN 'Action Taken: ' || PHD.Comment
        ELSE 'No Actions'
    END AS ActionDetails,
    PT.Tag AS TagDetails,
    CASE 
        WHEN RP.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    COALESCE(NULLIF(PD.PostCount, 0), 'No Tags Found') AS RelatedTags
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryData PHD ON RP.PostId = PHD.PostId
LEFT JOIN 
    (SELECT 
         T.TagName AS Tag, COUNT(*) AS PostCount 
     FROM 
         PopularTags PT
     GROUP BY 
         T.TagName
    ) PD ON RP.PostId = PD.PostId
LEFT JOIN 
    (SELECT 
         T.TagName FROM Tags T WHERE T.IsModeratorOnly = 1) MT ON RP.PostId = MT.TagName
WHERE 
    (RP.UpVoteCount - RP.DownVoteCount) > 10
ORDER BY 
    RP.ViewCount DESC, RP.CreationDate DESC
LIMIT 100;
