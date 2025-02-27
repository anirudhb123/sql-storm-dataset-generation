
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedStatus
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostScoreDetails AS (
    SELECT 
        RP.*,
        CASE 
            WHEN RP.Score > 0 THEN 'Positive'
            WHEN RP.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        RankedPosts RP
),
PopulatedTags AS (
    SELECT 
        P.Id AS PostId,
        GROUP_CONCAT(T.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT Id, SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1) TagName
         FROM Posts P
         JOIN (SELECT @rownum := @rownum + 1 AS n FROM 
         (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
          UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 
          UNION SELECT 10) numbers, (SELECT @rownum := 0) r) numbers 
         ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) >= numbers.n - 1) AS T 
    ON P.Id = P.Id
    GROUP BY 
        P.Id
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(PH.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    PSD.PostId,
    PSD.Title,
    PSD.Author,
    PSD.CreationDate,
    PSD.Score,
    PSD.ViewCount,
    PSD.ScoreCategory,
    PT.TagsList,
    COALESCE(PHS.CloseReopenCount, 0) AS CloseReopenStatus,
    PHS.LastHistoryDate,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PSD.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PSD.PostId AND V.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PSD.PostId AND V.VoteTypeId = 3) AS DownvoteCount
FROM 
    PostScoreDetails PSD
LEFT JOIN 
    PopulatedTags PT ON PSD.PostId = PT.PostId
LEFT JOIN 
    PostHistorySummary PHS ON PSD.PostId = PHS.PostId
WHERE 
    PSD.Rank <= 5 
AND 
    PSD.AcceptedStatus IN (-1, (SELECT MAX(AcceptedAnswerId) FROM Posts WHERE ParentId = PSD.PostId))
ORDER BY 
    PSD.Score DESC, 
    PSD.ViewCount DESC, 
    PSD.CreationDate DESC;
