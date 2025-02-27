WITH RECURSIVE UserReputation AS (
    -- Calculate the total reputation of users along with the number of badges they have
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    -- Capture recent posts along with their user information and the score of answers
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.Score AS PostScore,
        COALESCE((SELECT COUNT(*) FROM Posts A WHERE A.ParentId = P.Id AND A.PostTypeId = 2), 0) AS AnswerCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostHistoryAnalytics AS (
    -- Analyze post history types and their last edit dates in the last 30 days
    SELECT 
        PH.PostId,
        P.Title,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.BadgeCount,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.PostScore,
    PH.PostHistoryTypeId,
    PH.HistoryDate
FROM UserReputation R
JOIN RecentPosts RP ON R.UserId = RP.OwnerUserId
LEFT JOIN PostHistoryAnalytics PH ON RP.PostId = PH.PostId AND PH.EditRank = 1
WHERE R.Reputation > 1000 -- Filter users with reputation above a certain threshold
ORDER BY R.Reputation DESC, RP.CreationDate DESC
LIMIT 100;
