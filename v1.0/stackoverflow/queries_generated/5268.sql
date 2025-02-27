WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        u.DisplayName AS Closer
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate >= NOW() - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.*,
        COALESCE(cp.CloseDate, 'Not Closed') AS ClosedStatus,
        COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
        COALESCE(cp.Closer, 'N/A') AS CloserName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    *,
    (ViewCount + 2 * AnswerCount + 3 * CommentCount) AS EngagementScore
FROM 
    TopQuestions
ORDER BY 
    EngagementScore DESC, 
    CreationDate DESC;
