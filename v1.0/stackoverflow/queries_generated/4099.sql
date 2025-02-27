WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(PV.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(PV.DownVoteCount, 0) AS TotalDownVotes,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.UserId AND B.TagBased = 1) AS TagBasedBadgeCount
FROM 
    UserReputation U
LEFT JOIN 
    UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN 
    PostVotes PV ON PV.PostId IN (
        SELECT 
            Id 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = U.UserId
    )
WHERE 
    U.Reputation > 100
ORDER BY 
    U.Reputation DESC, 
    U.DisplayName ASC
LIMIT 10
OFFSET 5;
