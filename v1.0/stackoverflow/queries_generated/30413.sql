WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate < NOW() - INTERVAL '1 year' 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    HAVING 
        COUNT(DISTINCT P.Id) > 5 OR COUNT(DISTINCT C.Id) > 10
),
PostScoreRatings AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(UPVOTES.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DOWNVOTES.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN P.CommentCount > 0 THEN 1 END) AS CommentedCount
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) UPVOTES ON P.Id = UPVOTES.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVoteCount FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) DOWNVOTES ON P.Id = DOWNVOTES.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        RANK() OVER (ORDER BY PS.Score DESC) AS PostRank
    FROM 
        PostScoreRatings PS
    WHERE 
        PS.Score >= 10 AND PS.CommentedCount > 5
)
SELECT 
    UA.DisplayName,
    UA.UserId,
    UA.Reputation,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.UpVoteCount,
    TP.DownVoteCount,
    CASE 
        WHEN TP.Score >= (SELECT AVG(Score) FROM TopPosts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS ScoreCategory
FROM 
    RecursiveUserActivity UA
JOIN 
    TopPosts TP ON UA.UserId = TP.PostId
ORDER BY 
    UA.UserRank, TP.PostRank;
