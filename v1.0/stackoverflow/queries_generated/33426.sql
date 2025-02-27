WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        R.TotalPosts,
        R.Questions,
        R.Answers,
        R.TotalScore,
        R.AvgViews,
        R.OwnerUserId
    FROM Users U
    JOIN UserBadgeCounts B ON U.Id = B.UserId
    JOIN RecentPostStats R ON U.Id = R.OwnerUserId
    ORDER BY U.Reputation DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    R.TotalScore,
    R.AvgViews
FROM TopUsers U
JOIN RecentPostStats R ON U.Id = R.OwnerUserId
LEFT JOIN PostHistory PH ON PH.UserId = U.Id AND PH.CreationDate >= NOW() - INTERVAL '30 days'
WHERE R.TotalPosts > 0
ORDER BY U.BadgeCount DESC, R.TotalScore DESC;

-- Further expanding on relevant join aspects, particularly focusing on the relationship 
-- between votes and posts, the aggregate metrics can further reveal the engagements of 
-- the top users as well.
WITH VotesMetrics AS (
    SELECT 
        P.OwnerUserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    B.BadgeCount,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    R.TotalScore,
    R.AvgViews,
    VM.UpVotes,
    VM.DownVotes,
    VM.TotalVotes
FROM TopUsers U
JOIN RecentPostStats R ON U.Id = R.OwnerUserId
JOIN UserBadgeCounts B ON U.Id = B.UserId
JOIN VotesMetrics VM ON U.Id = VM.OwnerUserId
WHERE R.TotalPosts > 0
ORDER BY U.Reputation DESC, VM.TotalVotes DESC;
