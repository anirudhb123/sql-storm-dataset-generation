WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(CASE WHEN B.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedBadges,
        SUM(CASE WHEN B.TagBased = 0 THEN 1 ELSE 0 END) AS NamedBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
VoteActivity AS (
    SELECT 
        V.UserId,
        COUNT(*) AS TotalVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId IN (3, 10) THEN 1 END) AS Downvotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(VA.TotalVotes, 0) AS TotalVotes,
        COALESCE(VA.Upvotes, 0) AS UpVotes,
        COALESCE(VA.Downvotes, 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        VoteActivity VA ON U.Id = VA.UserId
),
RankedUserActivity AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY UA.TotalScore DESC, UA.TotalPosts DESC, UA.DisplayName) AS ScoreRank
    FROM 
        UserActivity UA
)
SELECT 
    RUA.UserId,
    RUA.DisplayName,
    RUA.GoldBadges,
    RUA.SilverBadges,
    RUA.BronzeBadges,
    RUA.TotalPosts,
    RUA.Questions,
    RUA.Answers,
    RUA.TotalScore,
    RUA.TotalVotes,
    RUA.UpVotes,
    RUA.DownVotes,
    CASE 
        WHEN RUA.TotalScore = 0 THEN 'Needs More Activity'
        WHEN RUA.ScoreRank <= 10 THEN 'Top User'
        WHEN RUA.TotalPosts > 100 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS ActivityLevel
FROM 
    RankedUserActivity RUA
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Users U
        WHERE U.Id = RUA.UserId AND U.Reputation < 50
    )
ORDER BY 
    RUA.ScoreRank, RUA.DisplayName;
