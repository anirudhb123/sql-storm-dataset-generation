WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select Questions as root nodes
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        cte.Level + 1,
        p2.CreationDate
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE cte ON p2.ParentId = cte.Id
    WHERE 
        p2.PostTypeId = 2 -- Select Answers
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
VoteDetail AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CtePostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Count of edits (Title, Body, Tags)
    GROUP BY 
        ph.UserId, 
        ph.PostId
),
PostDetails AS (
    SELECT 
        p.Title,
        p.Id AS PostId,
        u.DisplayName AS Author,
        pp.UpVotes,
        pp.DownVotes,
        cte.EditCount,
        cte.Level AS PostLevel
    FROM 
        Posts p
    LEFT JOIN 
        UserPostStats u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        VoteDetail pp ON p.Id = pp.PostId
    LEFT JOIN 
        CtePostHistory cte ON p.Id = cte.PostId
),
FinalStats AS (
    SELECT 
        pd.Author,
        COUNT(pd.PostId) AS TotalPosts,
        SUM(COALESCE(pd.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(pd.DownVotes, 0)) AS TotalDownVotes,
        AVG(pd.EditCount) AS AvgEdits,
        MAX(pd.PostLevel) AS MaxLevel
    FROM 
        PostDetails pd
    GROUP BY 
        pd.Author
)

SELECT 
    fs.Author,
    fs.TotalPosts,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.AvgEdits,
    fs.MaxLevel
FROM 
    FinalStats fs
WHERE 
    fs.TotalPosts > 10 -- Filtering for users with more than 10 posts
ORDER BY 
    fs.TotalUpVotes DESC
LIMIT 10; -- Top 10 users by upvotes
