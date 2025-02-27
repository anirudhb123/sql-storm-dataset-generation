WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1 
            WHEN V.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS NetVotes,
        SUM(CASE 
            WHEN B.Class = 1 THEN 3 
            WHEN B.Class = 2 THEN 2 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS TotalBadgePoints
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COALESCE(PV.CommentCount, 0) AS CommentCount,
        COALESCE(PV.AnswerCount, 0) AS AnswerCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount,
            SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
        FROM Comments
        GROUP BY PostId
    ) PV ON P.Id = PV.PostId
),
UserPostSummary AS (
    SELECT 
        P.UserId,
        COUNT(P.PostId) AS TotalPosts,
        SUM(P.UpvoteCount) AS TotalUpvotes,
        SUM(P.DownvoteCount) AS TotalDownvotes,
        AVG(P.UserPostRank) AS AvgUserPostRank
    FROM PostAnalytics P
    GROUP BY P.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    US.TotalPosts,
    US.TotalUpvotes,
    US.TotalDownvotes,
    US.AvgUserPostRank,
    US.TotalPosts * 1.5 + US.TotalUpvotes - US.TotalDownvotes AS PerformanceScore,
    CASE 
        WHEN US.TotalPosts > 100 THEN 'Expert'
        WHEN US.TotalPosts > 50 THEN 'Intermediate'
        ELSE 'Novice' 
    END AS UserLevel,
    COALESCE(US.TotalUpvotes - US.TotalDownvotes, 0) AS NetVotes,
    (SELECT STRING_AGG(DISTINCT B.Name, ', ') FROM Badges B WHERE B.UserId = U.UserId) AS BadgeNames
FROM Users U
JOIN UserPostSummary US ON U.Id = US.UserId
LEFT JOIN UserScores S ON U.Id = S.UserId
WHERE U.Reputation > 1000
ORDER BY PerformanceScore DESC, U.DisplayName ASC
LIMIT 100;
