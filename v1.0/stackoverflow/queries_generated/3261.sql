WITH UserVotes AS (
    SELECT 
        v.UserId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    GROUP BY v.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    JOIN Users u ON p.OwnerUserId = u.Id
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
        p.Title,
        p.PostId,
        p.PostStatus,
        p.PostRank,
        p.AnswerCount,
        p.CommentCount
    FROM Users u
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
    JOIN PostStats p ON u.Id = p.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalUpVotes,
    TotalDownVotes,
    Title,
    PostId,
    PostStatus,
    AnswerCount,
    CommentCount
FROM UserPostDetails
WHERE TotalUpVotes - TotalDownVotes > 5
  AND PostRank = 1
  AND PostStatus = 'Open'
ORDER BY TotalUpVotes DESC, Title;
