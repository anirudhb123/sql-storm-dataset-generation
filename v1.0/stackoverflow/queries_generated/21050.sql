WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (4, 10) THEN 1 ELSE 0 END), 0) AS OffenseOrDeletion,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Badges B 
    GROUP BY 
        B.UserId
), UserStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Upvotes,
        UA.Downvotes,
        UA.OffenseOrDeletion,
        UA.PostsCreated,
        UA.CommentsMade,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY (UA.Upvotes - UA.Downvotes) DESC) AS Rank
    FROM 
        UserActivity UA
    LEFT JOIN 
        UserBadges UB ON UA.UserId = UB.UserId
)
SELECT 
    UserId,
    DisplayName,
    Upvotes,
    Downvotes,
    OffenseOrDeletion,
    PostsCreated,
    CommentsMade,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Rank,
    CASE
        WHEN PostsCreated = 0 THEN 'New Member'
        WHEN PostsCreated < 10 THEN 'Novice'
        ELSE 'Experienced'
    END AS UserLevel,
    CASE 
        WHEN Upvotes - Downvotes > 0 THEN 'Positive'
        WHEN Upvotes - Downvotes = 0 THEN 'Neutral'
        ELSE 'Negative'
    END AS OverallReputation
FROM 
    UserStats
WHERE 
    (Upvotes - Downvotes > 5 OR GoldBadges > 0 OR SilverBadges > 2)
    AND NOT EXISTS (
        SELECT 1 
        FROM Badges B
        WHERE B.UserId = UserStats.UserId AND B.Class = 1 
        HAVING COUNT(*) > 1
    )
ORDER BY 
    Rank, DisplayName;

-- Including additional insights by combining posts linked to similar tags
WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS RelatedTags
    FROM 
        Posts P
    JOIN 
        Tags T ON T.ExcerptPostId = P.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
    GROUP BY 
        P.Id
), UserTags AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(DISTINCT T.TagName, ', ') AS UserTags
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    JOIN 
        Tags T ON T.ExcerptPostId = P.Id
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    COALESCE(UP.UserTags, 'No tags') AS UserTags,
    COALESCE(TP.RelatedTags, 'No related posts') AS RelatedTags
FROM 
    Users U
LEFT JOIN 
    UserTags UP ON U.Id = UP.UserId
LEFT JOIN 
    TaggedPosts TP ON TP.PostId IN (
        SELECT PostId FROM Posts WHERE OwnerUserId = U.Id
    )
ORDER BY 
    U.DisplayName;
