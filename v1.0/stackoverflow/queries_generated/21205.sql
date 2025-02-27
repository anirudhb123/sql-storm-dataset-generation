WITH UserAggregates AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikis,
        MAX(U.Reputation) AS Reputation,
        MAX(U.CreationDate) AS AccountCreationDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        P.Title,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    AND PH.PostHistoryTypeId IN (10, 11, 12, 13) -- Filter for Close, Reopen, Delete, Undelete actions
),
BadgedUsers AS (
    SELECT 
        U.Id,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
UserVoteStatistics AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalWikis,
    COALESCE(BU.BadgeCount, 0) AS BadgeCount,
    COALESCE(UVS.UpVotes, 0) AS UpVotes,
    COALESCE(UVS.DownVotes, 0) AS DownVotes,
    (SELECT COUNT(*) FROM RecentPostHistory RPH WHERE RPH.UserId = UA.UserId AND RPH.rn = 1) AS RecentPostActions,
    (CASE 
        WHEN UA.Reputation > 1000 THEN 'Expert'
        WHEN UA.Reputation IS NULL THEN 'New User'
        ELSE 'Regular User'
    END) AS UserType,
    MAX(PH.Comment) FILTER (WHERE PH.PostHistoryTypeId = 10) AS LastClosedComment
FROM UserAggregates UA
LEFT JOIN BadgedUsers BU ON UA.UserId = BU.Id
LEFT JOIN UserVoteStatistics UVS ON UA.UserId = UVS.UserId
LEFT JOIN RecentPostHistory RPH ON UA.UserId = RPH.UserId
LEFT JOIN PostHistory PH ON RPH.PostId = PH.PostId AND RPH.UserId = PH.UserId
GROUP BY 
    UA.UserId, UA.DisplayName, UA.TotalPosts,
    UA.TotalQuestions, UA.TotalAnswers, UA.TotalWikis,
    BU.BadgeCount, UVS.UpVotes, UVS.DownVotes
ORDER BY UA.TotalPosts DESC
LIMIT 100;
