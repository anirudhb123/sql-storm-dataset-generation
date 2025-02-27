
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(B.Class) AS BadgeClassSum,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT P2.Id) AS RelatedPostsCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN 
        Posts P2 ON PL.RelatedPostId = P2.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01' AS DATE) - 30 
    GROUP BY 
        P.Id, P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.BadgeCount,
        U.BadgeClassSum,
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.RelatedPostsCount,
        COALESCE(PS.UpVotes - PS.DownVotes, 0) AS Score
    FROM 
        UserBadges U
    JOIN 
        PostStats PS ON U.UserId = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    CS.PostId,
    CS.CommentCount,
    CS.UpVotes,
    CS.DownVotes,
    CS.RelatedPostsCount,
    CS.BadgeCount,
    CS.BadgeClassSum,
    CASE 
        WHEN CS.Score IS NULL THEN 'No Votes'
        WHEN CS.Score = 0 THEN 'Neutral Score'
        WHEN CS.Score < 0 THEN 'Overall Negative'
        ELSE 'Overall Positive' 
    END AS ScoreCategory
FROM 
    CombinedStats CS
JOIN 
    Users U ON CS.OwnerUserId = U.Id
ORDER BY 
    CS.Score DESC, 
    CS.CommentCount DESC 
OFFSET 50 ROWS FETCH NEXT 100 ROWS ONLY;
