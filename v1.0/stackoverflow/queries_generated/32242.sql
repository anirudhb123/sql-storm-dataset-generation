WITH RECURSIVE UserReputation AS (
    -- CTE to calculate the reputation score for each user, primarily focusing on their activities
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROUND(COALESCE(SUM(P.Score), 0) + (COALESCE(SUM(CASE WHEN B.Class = 1 THEN 3 WHEN B.Class = 2 THEN 2 WHEN B.Class = 3 THEN 1 END), 0) * 100), 0) AS ReputationScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
UserBadges AS (
    -- CTE to retrieve users along with their badges
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostInfo AS (
    -- CTE to aggregate post information with tags and their respective counts
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- filtering posts created in the last year
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    R.ReputationScore,
    B.BadgeCount,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.Tags
FROM 
    UserReputation R
JOIN 
    UserBadges B ON R.UserId = B.UserId
LEFT JOIN 
    PostInfo P ON U.Id = P.OwnerUserId  -- Assuming that the Posts table should reference back to Users
WHERE 
    R.ReputationScore > 500  -- Filtering users with reputation greater than 500
    AND B.BadgeCount > 0  -- Users must have at least one badge
ORDER BY 
    R.ReputationScore DESC,
    P.Score DESC;  -- Ordering by reputation and post score
