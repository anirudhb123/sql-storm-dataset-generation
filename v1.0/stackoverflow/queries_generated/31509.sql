WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.ParentId,
        rp.Level + 1
    FROM 
        Posts a
    JOIN 
        RecursivePosts rp ON a.ParentId = rp.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id  -- Answers
    LEFT JOIN 
        Votes v ON a.Id = v.PostId AND v.VoteTypeId = 8  -- Bounty votes
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalBounty,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    phs.LastClosedDate,
    phs.LastReopenedDate,
    phs.EditCount,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ups.TotalBounty DESC) AS UserRank
FROM 
    UserPostStats ups
JOIN 
    Users u ON u.Id = ups.UserId
JOIN 
    RecursivePosts ps ON ps.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId = ps.PostId
WHERE 
    (phs.LastClosedDate IS NULL OR phs.LastReopenedDate IS NOT NULL)  -- Consider only posts that are either open or reopened after being closed
ORDER BY 
    ups.TotalBounty DESC, ups.QuestionCount DESC;
