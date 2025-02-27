WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(P.AvgScore, 0) AS AvgScore,
        COALESCE(CL.TotalCloseVotes, 0) AS TotalCloseVotes,
        COALESCE(BA.BadgeCount, 0) AS BadgeCount,
        1 AS Level
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            AVG(Score) AS AvgScore 
        FROM 
            Posts 
        GROUP BY 
            OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS TotalCloseVotes
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId = 10  
        GROUP BY 
            UserId
    ) CL ON U.Id = CL.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) BA ON U.Id = BA.UserId
    WHERE 
        U.Reputation > 100
    UNION ALL
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(P.AvgScore, 0) AS AvgScore,
        COALESCE(CL.TotalCloseVotes, 0) AS TotalCloseVotes,
        COALESCE(BA.BadgeCount, 0) AS BadgeCount,
        Level + 1
    FROM 
        Users U
    JOIN UserActivity UA ON U.Id =  UA.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            AVG(Score) AS AvgScore 
        FROM 
            Posts 
        GROUP BY 
            OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS TotalCloseVotes
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId = 10  
        GROUP BY 
            UserId
    ) CL ON U.Id = CL.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) BA ON U.Id = BA.UserId
    WHERE 
        U.Reputation > 100
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.AvgScore,
        U.TotalCloseVotes,
        U.BadgeCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        UserActivity U
    WHERE 
        U.Level = 1
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.AvgScore,
    T.TotalCloseVotes,
    T.BadgeCount
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Reputation DESC;

This SQL query does the following:
1. It uses a recursive common table expression (CTE) to analyze user activity based on their post scores, close vote counts, and badge counts.
2. It selects users with a reputation greater than 100 so as to focus on more experienced users.
3. It retrieves the average score of posts made by each user and counts the total close votes they have received through the `PostHistory` table.
4. It aggregates the badge counts from the `Badges` table.
5. It ranks these users based on their reputation in descending order.
6. Finally, it selects the top 10 users with the highest reputation, showcasing their respective averages, close vote counts, and badge counts.
