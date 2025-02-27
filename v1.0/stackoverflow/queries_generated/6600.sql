WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- questions only
),
Answers AS (
    SELECT 
        parent.Id AS ParentPostId,
        COUNT(child.Id) AS AnswerCount
    FROM 
        Posts parent
    LEFT JOIN 
        Posts child ON parent.Id = child.ParentId
    WHERE 
        parent.PostTypeId = 1 -- questions only
    GROUP BY 
        parent.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- questions only
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.Score) > 0
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes c ON ph.Comment::jsonb->>'CloseReasonId'::integer = c.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AcceptedAnswerId,
    rp.OwnerDisplayName,
    a.AnswerCount,
    tu.DisplayName AS TopUserName,
    tu.TotalScore,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    Answers a ON rp.PostId = a.ParentPostId
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC 
LIMIT 100;
