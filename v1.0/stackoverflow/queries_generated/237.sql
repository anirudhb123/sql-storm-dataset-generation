WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '6 months'
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostSummary AS (
    SELECT 
        R.OwnerDisplayName,
        R.Title,
        R.CreationDate,
        R.UpVoteCount,
        R.DownVoteCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        CASE 
            WHEN R.UpVoteCount > R.DownVoteCount THEN 'Positive'
            WHEN R.UpVoteCount < R.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts R
    LEFT JOIN 
        UserBadges UB ON R.OwnerUserId = UB.UserId
)
SELECT 
    P.OwnerDisplayName,
    P.Title,
    P.CreationDate,
    P.UpVoteCount,
    P.DownVoteCount,
    P.GoldBadges,
    P.SilverBadges,
    P.BronzeBadges,
    P.Sentiment,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    (SELECT AVG(S.Score) FROM Posts S WHERE S.ParentId = P.Id) AS AvgAnswerScore
FROM 
    PostSummary P
WHERE 
    P.GoldBadges > 0 OR P.SilverBadges > 0
ORDER BY 
    P.CreationDate DESC
LIMIT 50;
