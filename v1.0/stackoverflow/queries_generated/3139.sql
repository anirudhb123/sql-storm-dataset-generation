WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVotesRank,
        RANK() OVER (ORDER BY DownVotes DESC) AS DownVotesRank
    FROM 
        UserActivity UA
    JOIN 
        Users U ON UA.UserId = U.Id
),
QuestionAndAnswers AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
RecentActivity AS (
    SELECT 
        UA.UserId,
        COUNT(DISTINCT P.Id) AS RecentPostsCount,
        COUNT(DISTINCT C.Id) AS RecentCommentsCount
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId AND P.CreationDate >= NOW() - INTERVAL '30 days'
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        UA.UserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    UA.UpVotes,
    UA.DownVotes,
    QU.PostId,
    QU.Title,
    QU.CreationDate,
    QU.Score,
    QU.AnswerCount,
    RA.RecentPostsCount,
    RA.RecentCommentsCount
FROM 
    TopUsers TU
JOIN 
    UserActivity UA ON TU.UserId = UA.UserId
JOIN 
    QuestionAndAnswers QU ON QU.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE PostTypeId = 1)
JOIN 
    RecentActivity RA ON RA.UserId = TU.UserId
WHERE 
    (UA.UpVotes - UA.DownVotes) > 5
ORDER BY 
    TU.UpVotesRank, TU.DownVotesRank;
