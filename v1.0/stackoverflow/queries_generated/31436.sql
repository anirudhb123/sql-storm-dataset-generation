WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS AnswerScore,
        SUM(CASE WHEN bh.UserId = u.Id THEN 1 ELSE 0 END) AS TotalBadges,
        AVG(bh.Class) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (10, 11) THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (12, 13) THEN 1 END) AS DeleteVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.QuestionScore,
    u.AnswerScore,
    u.TotalBadges,
    u.AvgBadgeClass,
    p.Title,
    p.CreationDate,
    pv.UpVotes,
    pv.DownVotes,
    pv.CloseVotes,
    pv.DeleteVotes,
    COUNT(rp.Id) AS ChildPostsCount
FROM 
    UserPostStats u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    PostVoteStats pv ON p.Id = pv.PostId
LEFT JOIN 
    RecursivePostHierarchy rp ON p.Id = rp.ParentId
WHERE 
    u.TotalPosts > 10
GROUP BY 
    u.UserId, u.DisplayName, u.TotalPosts, u.TotalQuestions,
    u.TotalAnswers, u.QuestionScore, u.AnswerScore,
    u.TotalBadges, u.AvgBadgeClass, p.Title, p.CreationDate,
    pv.UpVotes, pv.DownVotes, pv.CloseVotes, pv.DeleteVotes
ORDER BY 
    u.TotalPosts DESC, u.AvgBadgeClass DESC;
