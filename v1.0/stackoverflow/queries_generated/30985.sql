WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 0

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        Votes V ON U.Id = V.UserId
    INNER JOIN 
        UserReputationCTE UR ON V.PostId IN (
            SELECT P.Id 
            FROM Posts P 
            WHERE P.OwnerUserId = UR.Id
        )
    WHERE 
        UR.Level < 3
)

, PostWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        P.CreationDate,
        P.LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
)

, RankedPosts AS (
    SELECT 
        P.Title,
        P.CommentCount,
        P.CreationDate,
        RANK() OVER (ORDER BY P.CommentCount DESC) AS RankByComments
    FROM 
        PostWithComments P
)

SELECT 
    UR.DisplayName,
    UR.Reputation,
    P.Title,
    P.CommentCount,
    P.RankByComments,
    P.CreationDate
FROM 
    UserReputationCTE UR
JOIN 
    RankedPosts P ON P.RankByComments <= 10
WHERE 
    UR.LastAccessDate >= NOW() - INTERVAL '30 days'
    AND UR.Reputation > 100
ORDER BY 
    UR.Reputation DESC, P.RankByComments;
This query does the following:

1. Defines a recursive Common Table Expression (`UserReputationCTE`) to gather users with a reputation greater than 0 and their levels based on their voting patterns within a few iterations.
2. Generates a temporary table (`PostWithComments`) that aggregates posts created in the last year, counting the comments associated with each post.
3. Ranks the posts based on their respective comment counts.
4. Selects users with a reputation greater than 100, who accessed their accounts in the last 30 days, and joins it with the top-ranked posts, returning the result ordered by user reputation and comment ranking.
