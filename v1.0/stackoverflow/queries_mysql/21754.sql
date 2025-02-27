
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT COALESCE(P.AcceptedAnswerId, -1)) AS AcceptedAnswerCount,
        SUM(P.Score) AS TotalScore,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS AssociatedTags
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS T ON TRUE 
    GROUP BY 
        P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(UR.ReputationRank, 0) AS ReputationRank,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AssociatedTags, 'No Tags') AS AssociatedTags
    FROM 
        Users U
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UEng.UserId,
    U.DisplayName,
    UEng.ReputationRank,
    UEng.PostCount,
    UEng.AcceptedAnswerCount,
    UEng.TotalScore,
    CASE 
        WHEN UEng.ReputationRank <= 10 THEN 'Top User'
        WHEN UEng.ReputationRank <= 50 THEN 'Average User'
        WHEN YEAR(CURRENT_DATE) - YEAR(U.CreationDate) < 1 THEN 'New User'
        ELSE 'Experienced User'
    END AS UserCategory,
    UEng.AssociatedTags,
    CASE 
        WHEN UEng.TotalScore > 100 AND UEng.PostCount >= 10 THEN 
            'Highly Engaged'
        WHEN UEng.AcceptedAnswerCount >= 5 THEN 
            'Helpful User'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    Users U
JOIN 
    UserEngagement UEng ON U.Id = UEng.UserId
WHERE 
    U.LastAccessDate > NOW() - INTERVAL 30 DAY
ORDER BY 
    UEng.ReputationRank ASC, UEng.TotalScore DESC
LIMIT 50;
