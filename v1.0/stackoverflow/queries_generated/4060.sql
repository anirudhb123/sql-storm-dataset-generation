WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(DISTINCT V.PostId) AS UniquePostsVoted,
        COALESCE(SUM(B.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts
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
), Ranking AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY QuestionsAsked DESC, AnswersGiven DESC) AS UserRank
    FROM 
        UserActivity UA
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.QuestionsAsked,
    R.AnswersGiven,
    R.TotalComments,
    R.UniquePostsVoted,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    R.TotalPosts,
    R.UserRank,
    CASE 
        WHEN R.UserRank <= 10 THEN 'Top 10 Users' 
        WHEN R.UserRank <= 50 THEN 'Top 50 Users'
        ELSE 'Other Users' 
    END AS UserCategory
FROM 
    Ranking R
WHERE 
    (R.QuestionsAsked + R.AnswersGiven) > 0
ORDER BY 
    R.UserRank, R.DisplayName;

WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAccepted
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= now() - interval '90 days'
    GROUP BY 
        P.Id, P.Title
), PostRanking AS (
    SELECT 
        PE.*,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC, CommentCount DESC) AS EngagementRank
    FROM 
        PostEngagement PE
)
SELECT 
    PR.PostId,
    PR.Title,
    PR.CommentCount,
    PR.UpVotes,
    PR.DownVotes,
    PR.FavoriteCount,
    PR.IsAccepted,
    PR.EngagementRank,
    CASE 
        WHEN PR.EngagementRank <= 10 THEN 'Top Engaged Posts' 
        ELSE 'Other Posts' 
    END AS EngagementCategory
FROM 
    PostRanking PR
WHERE 
    PR.CommentCount > 0
ORDER BY 
    PR.EngagementRank;
