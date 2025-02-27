WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        COUNT(DISTINCT CASE WHEN P.ClosedDate IS NOT NULL THEN P.Id END) AS ClosedPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.Questions, 0) AS Questions,
        COALESCE(PA.Answers, 0) AS Answers,
        COALESCE(PA.ClosedPosts, 0) AS ClosedPosts
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.OwnerUserId
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        TotalPosts,
        Questions,
        Answers,
        ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, BadgeCount DESC, TotalPosts DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    ClosedPosts
FROM 
    RankedUsers
WHERE 
    Rank <= 100
ORDER BY 
    Rank;
