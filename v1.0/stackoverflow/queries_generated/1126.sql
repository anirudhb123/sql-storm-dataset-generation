WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2023-01-01'
),
CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        u.DisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation > 5000
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName,
        r.UserId
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts r ON ph.PostId = r.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    cc.TotalComments,
    ur.DisplayName AS Owner,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosureStatus,
    COALESCE(cp.UserDisplayName, 'N/A') AS ClosedBy
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.PostId = cc.PostId
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ScoreRank = 1
ORDER BY 
    rp.Score DESC 
LIMIT 10;
