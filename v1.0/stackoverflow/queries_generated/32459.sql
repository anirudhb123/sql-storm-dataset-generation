WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalPostHistoryRecords,
        SUM(CASE WHEN pht.Name = 'Post Closed' THEN 1 ELSE 0 END) AS TotalPostClosed,
        SUM(CASE WHEN pht.Name = 'Post Reopened' THEN 1 ELSE 0 END) AS TotalPostReopened
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.UserId
),
UserCombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalAcceptedAnswers,
        ups.TotalScore,
        COALESCE(pSummary.TotalPostHistoryRecords, 0) AS TotalPostHistoryRecords,
        COALESCE(pSummary.TotalPostClosed, 0) AS TotalPostClosed,
        COALESCE(pSummary.TotalPostReopened, 0) AS TotalPostReopened
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistorySummary pSummary ON ups.UserId = pSummary.UserId
)
SELECT 
    ucs.DisplayName,
    ucs.TotalPosts,
    ucs.TotalQuestions,
    ucs.TotalAnswers,
    ucs.TotalAcceptedAnswers,
    ucs.TotalScore,
    ucs.TotalPostHistoryRecords,
    ucs.TotalPostClosed,
    ucs.TotalPostReopened
FROM 
    UserCombinedStats ucs
WHERE 
    ucs.TotalPosts > 10
ORDER BY 
    ucs.TotalScore DESC
LIMIT 10;

WITH RecentVotes AS (
    SELECT 
        v.UserId,
        p.Title,
        v.CreationDate,
        vt.Name AS VoteType,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS rn
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    rv.UserId,
    rv.Title,
    STRING_AGG(rv.VoteType, ', ') AS VoteTypes,
    COUNT(rv.rn) AS VoteCount
FROM 
    RecentVotes rv
WHERE 
    rv.rn = 1
GROUP BY 
    rv.UserId, rv.Title
ORDER BY 
    VoteCount DESC;

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS AnsweredQuestions,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalCloseReopenActions,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.UserId = u.Id AND ph.PostId = p.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalCloseReopenActions DESC, TotalComments DESC;
