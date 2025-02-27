WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.UpVotes,
        UA.DownVotes,
        UA.CommentsCount,
        UA.QuestionsAsked,
        RANK() OVER (ORDER BY UA.UpVotes - UA.DownVotes DESC, UA.CommentsCount DESC) AS ActivityRank
    FROM 
        UserActivity UA
),
FilteredUsers AS (
    SELECT 
        U.DisplayName,
        R.ActivityRank,
        SUM(COALESCE(B.Class = 1, 0)) AS GoldBadges,
        SUM(COALESCE(B.Class = 2, 0)) AS SilverBadges,
        SUM(COALESCE(B.Class = 3, 0)) AS BronzeBadges
    FROM 
        RankedUsers R
    LEFT JOIN 
        Badges B ON R.UserId = B.UserId
    WHERE 
        R.ActivityRank <= 10
    GROUP BY 
        U.DisplayName, R.ActivityRank
)
SELECT 
    F.DisplayName,
    F.ActivityRank,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges
FROM 
    FilteredUsers F
ORDER BY 
    F.ActivityRank;
