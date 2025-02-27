WITH RecursivePostCTE AS (
    SELECT 
        Id,
        Title,
        Score,
        AcceptedAnswerId,
        ParentId,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE PostTypeId = 1  -- Only questions
),
PostWithAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score AS QuestionScore,
        a.Id AS AnswerId,
        a.Score AS AnswerScore,
        a.CreationDate AS AnswerCreationDate
    FROM RecursivePostCTE p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE a.PostTypeId = 2 -- Only answers
),
RankedQuestions AS (
    SELECT 
        QuestionId,
        Title,
        QuestionScore,
        AnswerId,
        AnswerScore,
        AnswerCreationDate,
        DENSE_RANK() OVER (PARTITION BY QuestionId ORDER BY AnswerScore DESC) AS AnswerRank
    FROM PostWithAnswers
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        COUNT(DISTINCT ps.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Only answers
    LEFT JOIN Posts ps ON u.Id = ps.OwnerUserId -- All posts
    GROUP BY u.Id
)
SELECT 
    uq.DisplayName,
    uq.TotalBounties,
    uq.AnswerCount,
    uq.PostCount,
    r.QuestionId,
    r.Title AS QuestionTitle,
    r.QuestionScore,
    r.AnswerId,
    r.AnswerScore,
    r.AnswerCreationDate,
    r.AnswerRank
FROM RankedQuestions r
JOIN UserStats uq ON r.AnswerId IN (
    SELECT Id 
    FROM Posts 
    WHERE OwnerUserId = uq.UserId
)
WHERE r.AnswerRank = 1  -- Only top answers
ORDER BY uq.TotalBounties DESC, r.QuestionScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Limit results to top 10
