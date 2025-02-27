WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- Considering posts from the last year
    GROUP BY 
        P.OwnerUserId
),

UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(P.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
)

SELECT 
    UEG.UserId,
    UEG.DisplayName,
    UEG.PostCount,
    UEG.BadgeCount,
    UEG.AverageScore,
    CASE 
        WHEN UEG.BadgeCount > 5 THEN 'High Activity'
        WHEN UEG.PostCount > 50 THEN 'Frequent Contributor'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserEngagement UEG
WHERE 
    UEG.PostCount IS NOT NULL
    AND UEG.BadgeCount IS NOT NULL
ORDER BY 
    UEG.PostCount DESC, UEG.BadgeCount DESC;

-- Subquery to calculate total votes received by posts owned by users with high badges
SELECT 
    P.OwnerUserId,
    SUM(V.VoteTypeId) AS TotalVotesReceived,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = P.OwnerUserId) AS TotalPosts
FROM 
    Posts P
JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.OwnerUserId IN (SELECT UserId FROM UserBadges WHERE BadgeCount > 5) -- Only considering users with high badge count
GROUP BY 
    P.OwnerUserId;

-- An outer join to identify posts with no votes but have been edited recently
SELECT 
    P.Id AS PostId,
    P.Title,
    P.LastEditDate,
    COUNT(V.Id) AS VotesCount
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.LastEditDate >= DATEADD(MONTH, -6, GETDATE()) -- Filter for recently edited posts
GROUP BY 
    P.Id, P.Title, P.LastEditDate
HAVING 
    COUNT(V.Id) = 0; -- Find posts with no votes at all
