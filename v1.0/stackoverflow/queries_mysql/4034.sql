
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        @row_number := IF(@current_user = P.OwnerUserId, @row_number + 1, 1) AS UserPostRank,
        @current_user := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_user := NULL) AS vars
    WHERE 
        P.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR) 
        OR P.LastActivityDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.PositivePosts,
    UA.NegativePosts,
    UA.AverageScore,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.LastActivityDate,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    BC.GoldBadges,
    BC.SilverBadges,
    BC.BronzeBadges
FROM 
    UserActivity UA
LEFT JOIN 
    PostStats PS ON UA.UserId = PS.OwnerUserId AND PS.UserPostRank <= 5
LEFT JOIN 
    BadgeCounts BC ON UA.UserId = BC.UserId
ORDER BY 
    UA.PostCount DESC,
    UA.AverageScore DESC
LIMIT 100;
