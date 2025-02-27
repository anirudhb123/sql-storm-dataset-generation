
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        BadgeCount,
        @rankReputation := IF(@prevReputation = Reputation, @rankReputation, @curRankReputation) AS ReputationRank,
        @curRankReputation := @curRankReputation + 1,
        @prevReputation := Reputation,
        @rankPostCount := IF(@prevPostCount = PostCount, @rankPostCount, @curRankPostCount) AS PostCountRank,
        @curRankPostCount := @curRankPostCount + 1,
        @prevPostCount := PostCount
    FROM 
        UserStats,
        (SELECT @curRankReputation := 0, @curRankPostCount := 0, @prevReputation := NULL, @prevPostCount := NULL, @rankReputation := 0, @rankPostCount := 0) AS vars
    ORDER BY 
        Reputation DESC, PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalBounty,
    BadgeCount,
    ReputationRank,
    PostCountRank
FROM 
    RankedUsers
WHERE 
    ReputationRank <= 10 OR PostCountRank <= 10
ORDER BY 
    Reputation DESC, PostCount DESC;
