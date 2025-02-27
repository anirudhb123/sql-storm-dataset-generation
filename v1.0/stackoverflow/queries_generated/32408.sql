WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Questions only
),
AnswerStats AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(AVG(a.Score), 0) AS AvgAnswerScore,
        MAX(a.CreationDate) AS LastAnswerDate
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment,
        U.DisplayName AS ClosedBy
    FROM PostHistory ph
    JOIN Users U ON ph.UserId = U.Id
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    AS.AnswerCount,
    AS.AvgAnswerScore,
    AS.LastAnswerDate,
    cp.ClosedDate,
    cp.ClosedBy,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS IsClosed
FROM RankedPosts rp
LEFT JOIN AnswerStats AS ON rp.PostId = AS.QuestionId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.PostRank = 1 -- Latest post for each user
ORDER BY rp.CreationDate DESC
LIMIT 100; -- Limiting to top 100 latest questions
