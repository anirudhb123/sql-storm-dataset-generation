WITH RecursivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.CreatedDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.ParentId,
        Score = 0
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.CreatedDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.ParentId,
        R.Score + COALESCE(V.CumulativeScore, 0) AS Score
    FROM Posts P
    JOIN RecursivePosts R ON P.ParentId = R.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE 
                WHEN VoteTypeId = 2 THEN 1 
                WHEN VoteTypeId = 3 THEN -1 
                ELSE 0 
            END) AS CumulativeScore
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
),
PostEvaluation AS (
    SELECT 
        RP.Id,
        RP.Title,
        U.DisplayName,
        RP.CreationDate,
        RP.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = RP.OwnerUserId AND B.Class = 1) AS GoldBadges,
        COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges
    FROM RecursivePosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    GROUP BY RP.Id, U.DisplayName, RP.Title, RP.CreationDate, RP.Score
),
FilteredPosts AS (
    SELECT 
        PE.Id,
        PE.Title,
        PE.DisplayName,
        PE.CreationDate,
        PE.Score,
        PE.CommentCount,
        PE.GoldBadges,
        PE.SilverBadges,
        PE.BronzeBadges,
        RANK() OVER (ORDER BY PE.Score DESC, PE.CommentCount DESC) AS Rank
    FROM PostEvaluation PE
    WHERE PE.Score > 0  -- Focusing on Posts with positive score
      AND PE.CommentCount IS NOT NULL
)
SELECT 
    *
FROM FilteredPosts
WHERE Rank <= 10  -- Top 10 Posts
ORDER BY GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC;
