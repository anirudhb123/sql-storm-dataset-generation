WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(NULLIF(P.OwnerUserId, -1), O.Id) AS RealOwnerUserId,
        O.Reputation,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Users O ON P.OwnerUserId = O.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
HighScorePosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.Reputation,
        RP.ScoreRank
    FROM 
        RankedPosts RP
    WHERE 
        RP.ScoreRank <= 10
),
PostDetails AS (
    SELECT 
        H.PostId,
        H.Reputation,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        HighScorePosts H
    LEFT JOIN 
        Comments C ON H.PostId = C.PostId
    LEFT JOIN 
        Votes V ON H.PostId = V.PostId
    LEFT JOIN 
        Posts P ON H.PostId = P.Id
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, '><')) AS T(TagName) ON TRUE
    GROUP BY 
        H.PostId, H.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1 
    GROUP BY 
        B.UserId
)
SELECT 
    P.Title AS PostTitle,
    P.Reputation AS OwnerReputation,
    P.CommentCount,
    P.VoteCount,
    P.Tags,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN P.Reputation > 500 THEN 'Experienced' 
        WHEN P.Reputation BETWEEN 200 AND 500 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS UserExperienceLevel
FROM 
    PostDetails P
LEFT JOIN 
    UserBadges UB ON P.PostId = UB.UserId
ORDER BY 
    P.Reputation DESC
LIMIT 50;

This query performs various intricate tasks including:

1. Uses Common Table Expressions (CTEs) to calculate ranked posts, high score posts, and post details.
2. Incorporates window functions for ranking posts based on score.
3. Uses outer joins to gather relevant data from multiple tables, ensuring we include all necessary information even when some records may be missing (like users with no posts).
4. Implements conditional aggregation with `COUNT` in connection to comments and votes, along with the `ARRAY_AGG` function for collecting tags.
5. Uses a conditionally derived experience level based on reputation, showcasing string expressions layered within the SQL syntax.
