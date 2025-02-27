WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
), CloseReasonSummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        ph.PostId
), UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
)
SELECT 
    u.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    r.Title AS TopQuestionTitle,
    r.Score AS TopQuestionScore,
    cr.CloseCount,
    cr.CloseReasons,
    COALESCE(rp.PostId, -1) AS TopPostId
FROM 
    UserStatistics us
INNER JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts r ON r.Rank = 1
LEFT JOIN 
    CloseReasonSummary cr ON cr.PostId = r.PostId
WHERE 
    us.QuestionCount > 0
    AND us.AnswerCount > 0 
ORDER BY 
    us.QuestionCount DESC, us.AnswerCount DESC;

### Explanation:
1. **Recursive CTE (RecursivePostHierarchy)**: Builds a hierarchy of posts starting with questions to understand parent-child relationships in responses and discussions.
2. **CloseReasonSummary CTE**: Aggregates close reasons for questions and counts the number of times each question has been closed.
3. **UserStatistics CTE**: Evaluates user activity metrics such as the number of questions asked, answers provided, and badges earned.
4. **RankedPosts CTE**: Ranks questions based on their score to identify the most influential or popular questions.
5. **Final SELECT Statement**: Combines all CTEs to present a summary of users with questions and answers, their top-ranked question, and related close reasons, filtering for active participants by ensuring they have both questions and answers.
