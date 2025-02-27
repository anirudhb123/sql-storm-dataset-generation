
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1) AS GoldBadges,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 2) AS SilverBadges,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 3) AS BronzeBadges
    FROM 
        Users U
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        @row_number := IF(@prev_score = P.Score, @row_number + 1, 1) AS Rank,
        @prev_score := P.Score
    FROM 
        Posts P, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND P.Score > 0
        AND P.PostTypeId = 1
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
),
RecentActivity AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.PostHistoryTypeId,
        @activity_rank := IF(@prev_post_id = PH.PostId, @activity_rank + 1, 1) AS ActivityRank,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory PH, (SELECT @activity_rank := 0, @prev_post_id := NULL) AS vars
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY 
        PH.PostId, PH.CreationDate DESC
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.VoteCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PP.Title,
    PP.Score,
    PP.AnswerCount,
    PP.ViewCount,
    R.ActivityRank,
    R.Comment,
    R.CreationDate AS RecentActivityDate
FROM 
    UserStats U
LEFT JOIN 
    PopularPosts PP ON PP.Rank <= 10
LEFT JOIN 
    RecentActivity R ON R.UserId = U.UserId AND R.ActivityRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    PP.Score DESC,
    R.CreationDate DESC;
