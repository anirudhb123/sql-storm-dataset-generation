WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteBalance
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 10 -- Filter users with reputation greater than 10
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.PostTypeId,
        COALESCE(UP.UpVotes, 0) AS UpVotes,
        COALESCE(DOWN.DownVotes, 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN UserVoteStats UP ON P.OwnerUserId = UP.UserId AND UP.UpVotes > 0
    LEFT JOIN UserVoteStats DOWN ON P.OwnerUserId = DOWN.UserId AND DOWN.DownVotes > 0
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) -- Only consider title, body, and tag edits
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.PostTypeId
),
HighlightedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerUserId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.EditCount,
        PHT.Name AS PostTypeName
    FROM PostStats PS
    INNER JOIN PostTypes PHT ON PS.PostTypeId = PHT.Id
    WHERE PS.UpVotes > PS.DownVotes -- Highlight posts with more upvotes than downvotes
    ORDER BY PS.UpVotes DESC
)
SELECT 
    HP.PostId,
    HP.Title,
    HP.OwnerUserId,
    HP.UpVotes,
    HP.DownVotes,
    HP.CommentCount,
    HP.EditCount,
    CONCAT('Post Type: ', HP.PostTypeName, ', Vote Ratio: ', 
           CASE WHEN HP.DownVotes = 0 THEN 'Inf'
                ELSE CAST(HP.UpVotes AS DECIMAL) / HP.DownVotes END) AS VoteRatio
FROM HighlightedPosts HP
WHERE HP.EditCount > 0 -- Only include posts that have been edited
  AND HP.CommentCount > 5 -- Only include posts with more than 5 comments
  AND NOT EXISTS (SELECT 1 FROM Posts P WHERE P.Id = HP.PostId AND P.ClosedDate IS NOT NULL) -- Exclude closed posts
ORDER BY HP.UpVotes DESC 
FETCH FIRST 10 ROWS ONLY;
