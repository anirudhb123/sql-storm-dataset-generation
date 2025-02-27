WITH RecursivePostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Score AS PostScore,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        1 AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Score AS PostScore,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        Depth + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostScores R ON P.ParentId = R.PostId  -- Recursive Join
)
, UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames  -- Aggregate badge names
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
, PostsWithVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(V.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(V.FavoriteCount, 0) AS FavoriteCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
            SUM(CASE WHEN VoteTypeId = 5 THEN 1 ELSE 0 END) AS FavoriteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.PostId,
    P.Title,
    P.Score,
    PWC.UpVoteCount,
    PWC.DownVoteCount,
    PWC.FavoriteCount,
    R.PostScore AS RecursiveScore,
    CASE 
        WHEN R.AcceptedAnswerId > 0 THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS UserBadges
FROM 
    Users U
INNER JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostsWithVoteCounts PWC ON P.Id = PWC.PostId
LEFT JOIN 
    RecursivePostScores R ON P.Id = R.PostId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    U.Reputation > 1000
    AND P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    P.Score DESC, U.Reputation DESC
LIMIT 100;
