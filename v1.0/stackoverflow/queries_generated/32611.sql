WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Top-level questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(ah.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.ClosedPostCount, 0) AS ClosedPostCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2  -- Answers
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            p.Id,
            COUNT(ph.Id) AS ClosedPostCount
        FROM 
            Posts p
        INNER JOIN 
            PostHistory ph ON p.Id = ph.PostId
        WHERE 
            ph.PostHistoryTypeId = 10  -- Closed posts
        GROUP BY 
            p.Id
    ) ph ON p.Id = ph.Id
)
SELECT 
    u.DisplayName,
    p.Title AS QuestionTitle,
    p.Score AS QuestionScore,
    ps.AnswerCount,
    ps.CommentCount,
    ps.ClosedPostCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
    RANK() OVER (ORDER BY ps.QuestionScore DESC) AS ScoreRank
FROM 
    UserActivity u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
JOIN 
    PostStatistics ps ON p.Id = ps.PostId
WHERE 
    ps.PostRank <= 10  -- Top 10 questions by Score
ORDER BY 
    ScoreRank;
