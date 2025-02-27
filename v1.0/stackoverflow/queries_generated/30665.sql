WITH RecursivePostChain AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        1 AS ChainLevel
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.AcceptedAnswerId,
        rpc.ChainLevel + 1
    FROM 
        Posts a
    JOIN 
        RecursivePostChain rpc ON a.ParentId = rpc.Id
)
, UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(v.VoteTypeId IS NOT NULL, 0) ) AS VoteCount,
        SUM(COALESCE(c.Id IS NOT NULL, 0)) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        PHT.Name AS HistoryType,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name IN ('Post Closed', 'Post Reopened') -- Focus on relevant history types
),
MostActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        RANK() OVER (ORDER BY ua.QuestionCount DESC, ua.AnswerCount DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionCount > 0 OR ua.AnswerCount > 0
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS Upvotes,  -- UpVotes
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS Downvotes  -- DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ua.DisplayName AS UserName,
    ua.QuestionCount,
    ua.AnswerCount,
    p.Title AS PostTitle,
    phd.HistoryType,
    phd.CreationDate AS HistoryDate,
    pp.Upvotes,
    pp.Downvotes,
    RANK() OVER (PARTITION BY ua.UserId ORDER BY pp.Upvotes - pp.Downvotes DESC) AS UserPostRank
FROM 
    UserActivity ua
JOIN 
    PostHistoryDetail phd ON ua.UserId = phd.UserId
JOIN 
    TopPosts pp ON phd.PostId = pp.Id
WHERE 
    ua.UserId IN (SELECT UserId FROM MostActiveUsers WHERE Rank <= 10)  -- Limit to top 10 active users
ORDER BY 
    UserName, HistoryDate DESC;
