
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users AS U
    LEFT JOIN 
        Votes AS V ON U.Id = V.UserId
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 ELSE NULL END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 ELSE NULL END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 ELSE NULL END) AS BronzeBadges
    FROM 
        Badges AS B
    GROUP BY 
        B.UserId
),
UserStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.UpVotes,
        UR.DownVotes,
        UR.QuestionCount,
        UR.AnswerCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserReputation AS UR
    LEFT JOIN 
        UserBadges AS UB ON UR.UserId = UB.UserId
)
SELECT TOP 10
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.QuestionCount,
    U.AnswerCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    (U.UpVotes - U.DownVotes) AS NetVotes,
    (U.QuestionCount + U.AnswerCount) AS TotalPosts,
    (U.GoldBadges + U.SilverBadges + U.BronzeBadges) AS TotalBadges
FROM 
    UserStats AS U
WHERE 
    (U.UpVotes - U.DownVotes) > 0
ORDER BY 
    TotalPosts DESC, NetVotes DESC;
