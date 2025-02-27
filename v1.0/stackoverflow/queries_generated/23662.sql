WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownvoteCount,
        string_agg(DISTINCT T.TagName, ', ') AS TagsAgg
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN LATERAL (
        SELECT substring(Tags, 2, length(Tags)-2) AS Tags
        FROM Posts
        WHERE Id = P.Id AND P.PostTypeId = 1
    ) AS TagData ON TRUE
    LEFT JOIN Tags T ON T.Id IN (SELECT unnest(string_to_array(TagData.Tags, '><'))::int)
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.PostTypeId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(*) FILTER (WHERE PH.UserId IS NULL) AS AnonymousEdits
    FROM PostHistory PH
    GROUP BY PH.PostId
),
MaxPostScores AS (
    SELECT 
        MAX(Score) AS MaxScore,
        PostTypeId
    FROM Posts
    GROUP BY PostTypeId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.PostRank,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.ReopenCount, 0) AS ReopenCount,
    CP.AnonymousEdits,
    RP.TagsAgg,
    CASE 
        WHEN RP.Score IS NULL THEN 'No Score'
        WHEN RP.Score = (SELECT MaxScore FROM MaxPostScores WHERE PostTypeId = RP.PostTypeId) THEN 'Top Post'
        ELSE 'Regular Post'
    END AS ScoreStatus
FROM RankedPosts RP
LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
WHERE RP.ViewCount > (
    SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = RP.PostTypeId
)
ORDER BY RP.PostRank;
