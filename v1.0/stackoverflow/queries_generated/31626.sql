WITH RecursivePostHierarchy AS (
    -- CTE to get all answers and the respective parent questions
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreatedDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    JOIN Posts a ON p.Id = a.ParentId
    WHERE a.PostTypeId = 2  -- Answers
),
PostHistoryDetails AS (
    -- Getting detailed post history information
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
UserReputation AS (
    -- Summarizing user reputation
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopAnswers AS (
    -- Find top answers based on score
    SELECT 
        PostId,
        SUM(Score) AS TotalScore,
        COUNT(*) AS AnswerCount
    FROM Posts
    WHERE PostTypeId = 2 -- Answers
    GROUP BY PostId
)
SELECT 
    q.PostId AS QuestionId,
    q.PostTitle,
    COALESCE(pa.AnswerCount, 0) AS AnswerCount,
    COALESCE(pa.TotalScore, 0) AS TotalAnswerScore,
    ph.HistoryCount,
    ph.HistoryTypes,
    ur.DisplayName AS TopUser,
    ur.TotalBadges,
    ur.TotalBounty,
    CASE 
        WHEN q.ViewCount IS NULL THEN 'No Views' 
        WHEN q.ViewCount > 1000 THEN 'Highly Viewed' 
        ELSE 'Moderately Viewed' 
    END AS ViewCategory
FROM RecursivePostHierarchy q
LEFT JOIN TopAnswers pa ON q.PostId = pa.PostId
LEFT JOIN PostHistoryDetails ph ON q.PostId = ph.PostId
LEFT JOIN UserReputation ur ON q.OwnerUserId = ur.UserId
WHERE q.Level = 1 -- Filtering only for questions
ORDER BY q.Score DESC, q.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;  -- Limiting to 100 results for performance

