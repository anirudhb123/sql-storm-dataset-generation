
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalViews,
        PS.QuestionCount,
        PS.AnswerCount,
        @rank := IF(@prev_total_views = PS.TotalViews AND @prev_badge_count = UB.BadgeCount, @rank, @rank + 1) AS UserRank,
        @prev_total_views := PS.TotalViews,
        @prev_badge_count := UB.BadgeCount
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId,
        (SELECT @rank := 0, @prev_total_views := NULL, @prev_badge_count := NULL) AS vars
),
TopPostStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.UserRank,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedUsers U
    JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
)
SELECT 
    TPS.UserId,
    TPS.DisplayName,
    TPS.UserRank,
    TPS.PostId,
    TPS.Title,
    TPS.CreationDate,
    TPS.Score,
    TPS.ViewCount,
    TPS.CommentCount,
    COALESCE(TPS.UpVotes, 0) - COALESCE(TPS.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN TPS.Score > 0 THEN 'Positive'
        WHEN TPS.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    @post_rank := IF(@prev_user_id = TPS.UserId AND @prev_view_count = TPS.ViewCount AND @prev_score = TPS.Score, @post_rank, @post_rank + 1) AS PostRank,
    @prev_user_id := TPS.UserId,
    @prev_view_count := TPS.ViewCount,
    @prev_score := TPS.Score
FROM 
    TopPostStats TPS,
    (SELECT @post_rank := 0, @prev_user_id := NULL, @prev_view_count := NULL, @prev_score := NULL) AS vars
ORDER BY 
    TPS.UserRank, NetVotes DESC;
