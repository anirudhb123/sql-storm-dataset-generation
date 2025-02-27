WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.PostTypeId, P.ViewCount, P.Score
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        RP.ScoreRank,
        U.DisplayName AS OwnerDisplayName,
        PHT.Comment AS LastHistoryComment,
        MAX(B.Date) FILTER (WHERE B.Class = 2) AS RecentSilverBadgeDate,
        MAX(B.Date) FILTER (WHERE B.Class = 3) AS RecentBronzeBadgeDate
    FROM 
        RankedPosts RP
    JOIN 
        Posts P ON RP.PostId = P.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
            SELECT MAX(PH2.CreationDate)
            FROM PostHistory PH2 
            WHERE PH2.PostId = P.Id 
            AND PH2.PostHistoryTypeId = 24  -- For Suggested Edit Applied
        )
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        RP.PostId, RP.Title, RP.ViewCount, RP.Score, RP.ScoreRank, U.DisplayName, PHT.Comment
),
FinalResults AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.Score,
        PD.ScoreRank,
        PD.OwnerDisplayName,
        COALESCE(PD.LastHistoryComment, 'No changes made') AS LastHistoryComment,
        CASE 
            WHEN PD.ScoreRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        CASE 
            WHEN PD.RecentSilverBadgeDate IS NOT NULL THEN 'Recently received a Silver Badge'
            WHEN PD.RecentBronzeBadgeDate IS NOT NULL THEN 'Recently received a Bronze Badge'
            ELSE 'No recent badges'
        END AS BadgeStatus
    FROM 
        PostDetails PD
    WHERE 
        PD.Score > 10 AND 
        PD.ViewCount > 100
),
Statistics AS (
    SELECT 
        PostCategory,
        COUNT(*) AS Count,
        AVG(ViewCount) AS AvgViewCount,
        SUM(CASE WHEN BadgeStatus LIKE 'Recently%' THEN 1 ELSE 0 END) AS RecentBadgeCount
    FROM 
        FinalResults
    GROUP BY 
        PostCategory
)
SELECT 
    FS.PostCategory,
    FS.Count,
    FS.AvgViewCount,
    FS.RecentBadgeCount,
    COALESCE(SB1.Count, 0) AS SilverBadgeCount,
    COALESCE(SB2.Count, 0) AS BronzeBadgeCount
FROM 
    Statistics FS
LEFT JOIN 
    (SELECT COUNT(*) AS Count FROM Badges WHERE Class = 2) SB1 ON TRUE
LEFT JOIN 
    (SELECT COUNT(*) AS Count FROM Badges WHERE Class = 3) SB2 ON TRUE;

