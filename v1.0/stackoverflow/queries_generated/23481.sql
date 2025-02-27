WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- filter for posts created in the last year
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate, 
        ph.Comment, 
        ph.UserDisplayName,
        ph.UserId,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId IN (11, 13) THEN 'Reopened/Undeleted'
            ELSE 'Other'
        END AS ClosureStatus
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 19, 20) -- Closed, Reopened, Deleted
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounty,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    cp.CreationDate AS ClosureDate,
    cp.ClosureStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.ScoreRank <= 5 OR cp.ClosureStatus IS NOT NULL) -- Get top 5 posts or any post that has been closed or reopened
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    ClosureDate DESC NULLS LAST; -- Last consider closure date

-- Detailed analysis of interactions with closed posts by users
SELECT
    userInteractions.UserId,
    userInteractions.DisplayName,
    COUNT(DISTINCT userInteractions.PostId) AS TotalInteractedPosts,
    SUM(CASE WHEN userInteractions.ClosureStatus = 'Closed' THEN 1 ELSE 0 END) AS TotalClosedInteractions,
    AVG(COALESCE(userInteractions.Score, 0)) AS AveragePostScore
FROM (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        cp.ClosureStatus,
        p.Score
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
) userInteractions
GROUP BY
    userInteractions.UserId, userInteractions.DisplayName
HAVING
    COUNT(DISTINCT userInteractions.PostId) > 10 -- Having interacted with more than 10 posts
ORDER BY 
    AveragePostScore DESC LIMIT 10;
