WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
AnswerStats AS (
    SELECT 
        p.ParentId AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AvgAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Questions
        AND a.PostTypeId = 2 -- Answers
    GROUP BY 
        p.ParentId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.VoteCount,
    COALESCE(as.AnswerCount, 0) AS TotalAnswers,
    COALESCE(as.AvgAnswerScore, 0) AS AvgAnswerScore,
    COALESCE(cp.ClosedCount, 0) AS ClosedPostsCount,
    CASE 
        WHEN cp.ClosedCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    AnswerStats as ON rp.Id = as.QuestionId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
