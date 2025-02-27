WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes, -- Count of Upvotes
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes -- Count of Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPostReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::integer = cr.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
AnswerStatistics AS (
    SELECT 
        p.ParentId AS QuestionId,
        COUNT(*) AS AnswerCount,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Answer
    GROUP BY 
        p.ParentId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasons,
    COALESCE(a.AverageScore, 0) AS AverageAnswerScore,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreDescription,
    CASE WHEN rg.IS_NOT_NULL THEN 'Has a Reputation' ELSE 'Reputation Unknown' END AS UserReputationStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostReasons cpr ON cpr.PostId = rp.PostId
LEFT JOIN 
    AnswerStatistics a ON a.QuestionId = rp.PostId
LEFT JOIN 
    Users rg ON rg.Id = rp.OwnerUserId
WHERE 
    rp.Rank <= 5 -- Top 5 latest posts of each type
ORDER BY 
    rp.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination to skip the first 5 and fetch the next 10

This query generates a detailed report of the top posts from the last year, categorizing them by type while including various statistics, such as upvotes, downvotes, and associated closure reasons. It employs CTEs, window functions, and unusual conditions for comprehensive performance benchmarking.
