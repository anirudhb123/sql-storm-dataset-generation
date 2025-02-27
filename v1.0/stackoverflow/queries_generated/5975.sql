WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        DATEDIFF(MINUTE, P.CreationDate, COALESCE(P.LastActivityDate, GETDATE())) AS ActiveDurationMinutes,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        UP.DisplayName AS OwnerName
    FROM 
        Posts P
    LEFT JOIN 
        Users UP ON P.OwnerUserId = UP.Id
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
EngagementScores AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        (U.PostCount * 0.4) + (U.QuestionCount * 0.3) + (U.AnswerCount * 0.2) + (U.CommentCount * 0.1) AS EngagementScore
    FROM 
        UserEngagement U
)
SELECT 
    ES.DisplayName,
    ES.EngagementScore,
    PM.PostId,
    PM.Title,
    PM.ActiveDurationMinutes,
    PM.ViewCount,
    PM.Score,
    PM.AnswerCount
FROM 
    EngagementScores ES
JOIN 
    PostMetrics PM ON ES.UserId = PM.OwnerUserId
ORDER BY 
    ES.EngagementScore DESC, PM.ActiveDurationMinutes DESC
LIMIT 100;
