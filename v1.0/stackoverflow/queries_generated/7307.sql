WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.AnswerCount,
        U.QuestionCount,
        U.UpVotes,
        U.DownVotes,
        P.PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.CreationDate,
        P.LastCommentDate
    FROM 
        UserStats U
    JOIN 
        PostStats P ON U.UserId = P.OwnerUserId
)
SELECT 
    C.DisplayName,
    SUM(C.Score) AS TotalPostScore,
    AVG(C.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT C.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN C.LastCommentDate IS NOT NULL THEN C.PostId END) AS PostsWithComments,
    MAX(C.Reputation) AS MaxReputation
FROM 
    CombinedStats C
GROUP BY 
    C.DisplayName
ORDER BY 
    TotalPostScore DESC
LIMIT 10;
