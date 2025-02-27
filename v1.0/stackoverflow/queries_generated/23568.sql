WITH ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
RecentAbandonments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        DATEDIFF(NOW(), p.LastActivityDate) AS DaysInactive,
        COALESCE(c.ClosedDate, '9999-12-31') AS CloseDate,
        CASE 
            WHEN p.AnswerCount = 0 THEN 'No Answers'
            WHEN p.AnswerCount > 1 THEN 'Multiple Answers'
            ELSE 'Single Answer'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT Id, ClosedDate FROM Posts WHERE ClosedDate IS NOT NULL) c ON p.Id = c.Id
    WHERE 
        DATEDIFF(NOW(), p.LastActivityDate) > 30 -- Posts inactive for more than 30 days
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.Score,
    ap.ViewCount,
    ap.CommentCount,
    ap.UpVotes,
    ap.DownVotes,
    ra.DaysInactive,
    ra.AnswerStatus,
    CASE 
        WHEN ra.CloseDate <= NOW() THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    ActivePosts ap
JOIN 
    RecentAbandonments ra ON ap.PostId = ra.PostId
WHERE 
    (ap.rn = 1 AND ap.Score > 0) -- considering only the most recent posts per user with a score greater than 0
    OR (ra.AnswerStatus = 'No Answers' AND ra.DaysInactive > 60)
ORDER BY 
    ap.Score DESC, ra.DaysInactive ASC
LIMIT 100;

-- This complex query combines different elements to provide insights into questions
-- that are both actively engaged and recently abandoned. It uses CTEs for modular
-- organization, joins to gather data, and incorporates case logic to derive 
-- insightful statuses while handling edge cases like inactivity and answer count.
