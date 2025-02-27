WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Low Reputation'
            WHEN Reputation < 500 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM Users
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts
    GROUP BY OwnerUserId
    HAVING COUNT(*) > 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Score,
        P.CreationDate,
        COALESCE(Pr.Username, 'Community User') AS PostOwner,
        (
            SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.PostId = P.Id
        ) AS CommentCount
    FROM Posts P
    LEFT JOIN Users Pr ON P.OwnerUserId = Pr.Id
)

SELECT 
    UA.UserId,
    RA.ReputationCategory,
    BA.BadgeCount,
    BA.BadgeNames,
    COALESCE(PA.PostCount, 0) AS TotalPosts,
    COALESCE(PA.QuestionCount, 0) AS Questions,
    COALESCE(PA.AnswerCount, 0) AS Answers,
    SUM(COALESCE(PT.Score, 0)) AS TotalScore
FROM UserReputation UA
LEFT JOIN UserBadges BA ON UA.UserId = BA.UserId
LEFT JOIN MostActiveUsers PA ON UA.UserId = PA.OwnerUserId
LEFT JOIN PostAnalytics PT ON UA.UserId = PT.OwnerUserId
GROUP BY UA.UserId, RA.ReputationCategory, BA.BadgeCount, BA.BadgeNames
HAVING SUM(COALESCE(PT.Score, 0)) > 10 OR (BA.BadgeCount IS NULL AND RA.ReputationCategory = 'Low Reputation')
ORDER BY TotalScore DESC
LIMIT 100
OFFSET 0;

-- Adding an additional outer join example
SELECT 
    P.Title,
    P.ViewCount,
    CASE 
        WHEN COALESCE(HH.PostHistoryCount, 0) > 0 THEN 'Has History'
        ELSE 'No History'
    END AS HistoryStatus
FROM Posts P
LEFT OUTER JOIN (
    SELECT PostId, COUNT(*) AS PostHistoryCount
    FROM PostHistory
    GROUP BY PostId
) HH ON P.Id = HH.PostId
WHERE P.CreationDate >= NOW() - INTERVAL '1 year' 
AND (P.Score IS NOT NULL OR P.Id < 50000)
ORDER BY P.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
