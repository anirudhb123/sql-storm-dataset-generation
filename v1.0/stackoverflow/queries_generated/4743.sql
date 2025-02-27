WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COALESCE(PS.ViewCount, 0) AS ViewCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.CommentCount, 0) AS CommentCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentActivityRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(ViewCount) AS ViewCount,
            SUM(AnswerCount) AS AnswerCount,
            SUM(CommentCount) AS CommentCount
        FROM 
            Posts
        GROUP BY 
            PostId
    ) PS ON P.Id = PS.PostId
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    P.Title,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    CASE 
        WHEN P.PostTypeId = 1 THEN 'Question'
        WHEN P.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    DENSE_RANK() OVER (ORDER BY U.TotalVotes DESC) AS UserRank
FROM 
    UserVoteStats U
JOIN 
    PostStats P ON P.PostId IN (SELECT RelatedPostId FROM PostLinks WHERE PostId = P.PostId)
WHERE 
    U.TotalVotes IS NOT NULL
    AND P.RecentActivityRank <= 5
ORDER BY 
    UserRank, P.CreationDate DESC;
