
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
             SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
             SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
             SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
             SELECT 8 UNION ALL SELECT 9) b) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1))
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        P.CreationDate,
        P.ViewCount,
        COALESCE(CAST(P.AnswerCount AS CHAR), '0') AS AnswerCount,
        COALESCE(CAST(P.CommentCount AS CHAR), '0') AS CommentCount,
        COALESCE(CAST(P.FavoriteCount AS CHAR), '0') AS FavoriteCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.LastActivityDate >= CURDATE() - INTERVAL 30 DAY
)
SELECT 
    P.Title,
    P.PostType,
    P.ViewCount,
    US.DisplayName AS TopUser,
    US.BadgeCount,
    TS.Tag,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore
FROM 
    PostAnalytics P
JOIN 
    UserBadges US ON P.PostId = US.UserId 
JOIN 
    TagStats TS ON P.Title LIKE CONCAT('%', TS.Tag, '%') 
WHERE 
    US.BadgeCount > 0
ORDER BY 
    P.ViewCount DESC, TS.TotalViews DESC
LIMIT 10;
