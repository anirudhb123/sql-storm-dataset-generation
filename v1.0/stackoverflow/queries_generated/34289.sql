WITH RecursiveUserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        RANK() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
), 
UserPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AverageScore,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC, PS.TotalPosts DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        UserPostStats PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.Reputation > 1000
), 
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        Posts P 
    JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(B.BadgeName, 'No Badge') AS LatestBadge,
    COALESCE(B.Class, 4) AS BadgeClass,
    C.Title AS ClosedPostTitle,
    C.CloseDate,
    C.CloseReason
FROM 
    TopUsers U
LEFT JOIN 
    RecursiveUserBadges B ON U.Id = B.UserId AND B.BadgeRank = 1
LEFT JOIN 
    ClosedPosts C ON C.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.Reputation DESC, 
    U.TotalPosts DESC, 
    C.CloseDate DESC;
