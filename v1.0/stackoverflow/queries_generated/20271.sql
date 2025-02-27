WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPostCloseCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS RecentClosedPosts,
        MAX(P.CreationDate) AS MostRecentCloseDate
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    AND PH.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotesCount, -- UpVotes
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotesCount -- DownVotes
    FROM Votes V
    GROUP BY V.UserId
),
RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS BadgeCount,
        COALESCE(RP.RecentClosedPosts, 0) AS RecentClosedPosts,
        COALESCE(UV.UpVotesCount, 0) AS UpVotes,
        COALESCE(UV.DownVotesCount, 0) AS DownVotes,
        RANK() OVER (ORDER BY COALESCE(UB.TotalBadges, 0) DESC, COALESCE(RP.RecentClosedPosts, 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN RecentPostCloseCounts RP ON U.Id = RP.OwnerUserId
    LEFT JOIN UserVotes UV ON U.Id = UV.UserId
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.BadgeCount,
    R.RecentClosedPosts,
    R.UpVotes,
    R.DownVotes,
    R.UserRank,
    CASE 
        WHEN R.BadgeCount = 0 
        THEN 'No badges earned yet! Keep contributing!' 
        ELSE 'Good job! You have earned badges!'
    END AS BadgeMessage,
    CASE 
        WHEN R.RecentClosedPosts > 5 THEN 'Consider reviewing your posts.' 
        ELSE 'You are actively participating!'
    END AS ParticipationMessage
FROM RankedUsers R
WHERE R.UserRank <= 10
ORDER BY R.UserRank, R.RecentClosedPosts DESC;
