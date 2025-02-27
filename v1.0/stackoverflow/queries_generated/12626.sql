-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        SUM(b.Id IS NOT NULL) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AcceptedAnswerId IS NOT NULL, false) AS HasAcceptedAnswer,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, a.AcceptedAnswerId
)
SELECT 
    us.UserId,
    us.PostsCount,
    us.QuestionsCount,
    us.AnswersCount,
    us.UpVotesCount,
    us.DownVotesCount,
    us.BadgesCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.HasAcceptedAnswer,
    ps.UpVotes,
    ps.DownVotes
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId  -- This will need adjustment based on how you wish to join User and Posts
ORDER BY 
    us.PostsCount DESC, ps.ViewCount DESC;
