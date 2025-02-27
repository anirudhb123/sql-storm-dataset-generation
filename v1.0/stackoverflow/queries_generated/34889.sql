WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(VoteCount.TotalVotes, 0) AS TotalVotes,
        COALESCE(CommentCount.CommentCount, 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VoteCount ON P.Id = VoteCount.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) CommentCount ON P.Id = CommentCount.PostId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.TotalVotes, 0)) AS VotesReceived,
        COUNT(DISTINCT PS.PostId) AS PostCount
    FROM 
        Users U
    JOIN RecursivePostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON PS.PostId = V.PostId
    WHERE 
        PS.PostRank <= 5 -- Consider only the top 5 posts for each user
    GROUP BY 
        U.Id, U.DisplayName
),
HighScorePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        U.DisplayName AS AuthorName
    FROM 
        Posts P
    JOIN RecursivePostStats PS ON P.Id = PS.PostId
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE 
        PS.Score > 10 -- High scoring posts
)
SELECT 
    U.DisplayName,
    U.VotesReceived,
    U.PostCount,
    COALESCE(STRING_AGG(DISTINCT H.Title, ', '), 'No high score posts') AS HighScorePostTitles,
    COALESCE(STRING_AGG(DISTINCT H.CreationDate::date::text, ', '), 'No high score posts') AS HighScorePostDates
FROM 
    TopUsers U
LEFT JOIN HighScorePosts H ON U.UserId = H.AuthorName
GROUP BY 
    U.UserId, U.DisplayName
ORDER BY 
    U.VotesReceived DESC, U.PostCount DESC
LIMIT 10;
