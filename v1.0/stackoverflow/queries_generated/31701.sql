WITH RecursivePostHierarchy AS (
    -- CTE to find all answers to questions and their respective users
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.ParentId,
        p.OwnerUserId,
        u.Reputation AS UserReputation,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate) AS RowNum
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 2 -- Only answers
),
UserBadges AS (
    -- Find users and their highest badge class
    SELECT 
        b.UserId,
        MAX(b.Class) AS MaxBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
TopAnswers AS (
    -- CTE to select top N answers for each question based on criteria
    SELECT 
        r.PostId,
        r.OwnerUserId,
        r.Score,
        r.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY r.ParentId ORDER BY r.Score DESC, r.CreationDate ASC) AS Rank
    FROM RecursivePostHierarchy r
    WHERE r.Score > 0 -- Only positive scored answers
)
SELECT 
    q.Title AS QuestionTitle,
    q.OwnerDisplayName AS QuestionOwner,
    q.CreationDate AS QuestionCreationDate,
    a.OwnerUserId AS AnswerOwner,
    a.Score AS AnswerScore,
    a.CreationDate AS AnswerCreationDate,
    ub.MaxBadgeClass,
    ub.BadgeCount,
    COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 9), 0) AS TotalBountyAmount,
    COALESCE(SUM(v.VoteTypeId) FILTER (WHERE v.VoteTypeId IN (2, 3)), 0) AS VoteCounts
FROM Posts q
JOIN TopAnswers a ON q.Id = a.ParentId AND a.Rank <= 3 -- Select top 3 answers for each question
LEFT JOIN UserBadges ub ON a.OwnerUserId = ub.UserId -- Join with user badges
LEFT JOIN Votes v ON a.PostId = v.PostId -- Optional join to get vote counts and bounties
WHERE q.PostTypeId = 1 -- Proceed only with questions
GROUP BY 
    q.Id, 
    q.Title, 
    q.OwnerDisplayName, 
    q.CreationDate, 
    a.OwnerUserId, 
    a.Score, 
    a.CreationDate, 
    ub.MaxBadgeClass, 
    ub.BadgeCount
ORDER BY 
    q.CreationDate DESC, 
    a.Score DESC;
