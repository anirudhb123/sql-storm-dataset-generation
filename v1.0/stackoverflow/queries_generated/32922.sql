WITH RECURSIVE UserActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MIN(CreationDate) AS FirstActivity,
        MAX(CreationDate) AS LastActivity
    FROM 
        Posts
    GROUP BY 
        UserId
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UA.TotalPosts,
        UA.Questions,
        UA.Answers,
        UA.FirstActivity,
        UA.LastActivity
    FROM 
        Users U
    LEFT JOIN UserActivity UA ON U.Id = UA.UserId
    WHERE 
        U.LastAccessDate > NOW() - INTERVAL '1 month'
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        P.CreationDate
    FROM 
        Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments 
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.PostType,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY PS.PostType ORDER BY PS.UpVotes DESC) AS Rank
    FROM 
        PostStats PS
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    TP.Title AS TopPostTitle,
    TP.UpVotes,
    TP.CommentCount,
    CASE 
        WHEN TP.HasAcceptedAnswer = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS AcceptedAnswer,
    UA.FirstActivity,
    UA.LastActivity,
    CASE 
        WHEN UA.LastActivity < NOW() - INTERVAL '1 month' THEN 'Inactive'
        ELSE 'Active' 
    END AS UserStatus
FROM 
    RecentActivity UA
LEFT JOIN TopPosts TP ON UA.UserId = TP.UserId
WHERE 
    TP.Rank <= 5
ORDER BY 
    UA.DisplayName, TP.UpVotes DESC;

