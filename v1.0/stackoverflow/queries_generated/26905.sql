WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        AVG(v.VoteTypeId = 2) AS AverageUpvotes,
        AVG(v.VoteTypeId = 3) AS AverageDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AcceptedQuestions,
        AverageUpvotes,
        AverageDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)

SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.AcceptedQuestions,
    ts.AverageUpvotes,
    ts.AverageDownvotes
FROM 
    TopUsers ts
JOIN 
    Users u ON ts.UserId = u.Id
WHERE 
    ts.Rank <= 10
ORDER BY 
    ts.Rank;

WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount
FROM 
    TagStats ts
WHERE 
    ts.PostCount > 0
ORDER BY 
    ts.PostCount DESC
LIMIT 10;

WITH RecentPostHistory AS (
    SELECT 
        p.Title,
        p.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '1 month'
    ORDER BY 
        ph.CreationDate DESC
)

SELECT 
    r.Title,
    r.CreationDate,
    r.UserDisplayName,
    r.EditDate,
    r.Comment,
    CASE 
        WHEN r.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        WHEN r.PostHistoryTypeId IN (24) THEN 'Suggested Edit Applied'
        ELSE 'Other'
    END AS EditType,
    r.Text
FROM 
    RecentPostHistory r
LIMIT 50;

WITH VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    p.Title,
    p.CreationDate,
    vs.UpVotes,
    vs.DownVotes,
    vs.AverageBounty
FROM 
    VoteSummary vs
JOIN 
    Posts p ON vs.PostId = p.Id
WHERE 
    vs.UpVotes > 0 OR vs.DownVotes > 0
ORDER BY 
    vs.UpVotes DESC, vs.DownVotes ASC
LIMIT 100;

WITH CommentAnalysis AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AverageCommentLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    p.Title,
    ca.CommentCount,
    ca.AverageCommentLength
FROM
