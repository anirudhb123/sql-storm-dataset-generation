WITH RankedUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE NULL END) AS CommentCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 ELSE NULL END) AS EditCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.PostTypeId
),
TopPosts AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        RANK() OVER (ORDER BY PS.UpVotes - PS.DownVotes DESC, PS.CommentCount DESC) AS PostRank
    FROM PostStats PS
    WHERE PS.PostTypeId = 1
),
RecursiveTags AS (
    SELECT
        T.Id,
        T.TagName,
        P.Tags,
        1 AS Level
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE P.PostTypeId = 1
    
    UNION ALL
    
    SELECT
        T.Id,
        T.TagName,
        P.Tags,
        RT.Level + 1
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN RecursiveTags RT ON RT.Tags LIKE '%' || T.TagName || '%'
    WHERE RT.Level < 3
)
SELECT
    U.DisplayName AS User,
    U.Reputation,
    U.CreationDate,
    TPost.Title AS TopPost,
    TPost.UpVotes,
    TPost.DownVotes,
    TPost.CommentCount,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount,
    (SELECT STRING_AGG(RT.TagName, ', ') FROM RecursiveTags RT WHERE RT.Tags LIKE '%' || TPost.Title || '%') AS RelatedTags
FROM RankedUsers U
JOIN TopPosts TPost ON U.Id = TPost.PostId 
WHERE U.UserRank <= 10
ORDER BY U.Reputation DESC, TPost.UpVotes DESC;

