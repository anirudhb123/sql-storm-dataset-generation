WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS Closed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerName,
    u.Reputation,
    COUNT(c.Id) AS TotalComments,
    phs.EditCount,
    phs.Closed,
    ue.TotalBounty,
    ue.UpVotes,
    ue.DownVotes
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    rp.PostRank = 1 -- Only the top post per user
    AND (phs.Closed = 1 OR phs.EditCount > 5) -- Filtering criteria
GROUP BY 
    p.Title, u.DisplayName, u.Reputation, phs.EditCount, phs.Closed, ue.TotalBounty, ue.UpVotes, ue.DownVotes
ORDER BY 
    ue.TotalBounty DESC, rp.Score DESC;
