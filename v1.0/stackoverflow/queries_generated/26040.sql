WITH UserBadgeCounts AS (
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
PopularPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    AND 
        P.Score > 0
),
RecentActivity AS (
    SELECT
        P.Id AS PostId,
        P.LastActivityDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    GROUP BY 
        P.Id, P.LastActivityDate
),
FinalBenchmark AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.BadgeCount,
        PP.PostId,
        PP.Title,
        PP.ViewCount,
        PP.Score,
        RA.CommentCount,
        RA.UpVotes,
        RA.DownVotes,
        RANK() OVER (PARTITION BY U.UserId ORDER BY PP.ViewCount DESC) AS PostRank
    FROM 
        UserBadgeCounts U
    JOIN 
        PopularPosts PP ON U.UserId = PP.OwnerDisplayName
    JOIN 
        RecentActivity RA ON PP.PostId = RA.PostId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostId,
    Title,
    ViewCount,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    PostRank
FROM 
    FinalBenchmark
WHERE 
    PostRank <= 5  -- Top 5 posts per user
ORDER BY 
    BadgeCount DESC, ViewCount DESC;
