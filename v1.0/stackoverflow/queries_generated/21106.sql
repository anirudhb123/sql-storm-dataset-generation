WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY CreationDate DESC) AS Rank
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
HighlightedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COALESCE(p.ClosedDate, 'No Closure') AS ClosedStatus,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Present' 
            ELSE 'No Accepted Answer'
        END AS AnswerStatus
    FROM 
        Posts p
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
        AND p.ViewCount > (
            SELECT AVG(ViewCount) 
            FROM Posts 
            WHERE CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
        )
),
PostChanges AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.UserDisplayName END) AS CloserUser
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    up.PostId,
    up.Title,
    up.ViewCount,
    up.Score,
    up.ClosedStatus,
    up.AnswerStatus,
    pc.FirstClosedDate,
    pc.CloserUser
FROM 
    HighlightedPosts up
LEFT JOIN 
    Votes v ON v.PostId = up.PostId AND v.VoteTypeId = 2  -- Counting UpVotes
LEFT JOIN 
    RankedUsers u ON u.Id = (SELECT TOP 1 Id 
                              FROM RankedUsers 
                              WHERE Rank <= 3)
LEFT JOIN 
    PostChanges pc ON pc.PostId = up.PostId
WHERE 
    up.Score > 5
    AND (u.Reputation IS NOT NULL OR up.ClosedStatus IS NULL)
ORDER BY 
    up.Score DESC, 
    up.ViewCount DESC, 
    pc.FirstClosedDate DESC NULLS LAST;

