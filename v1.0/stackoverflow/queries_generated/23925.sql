WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(UPPER(p.Body), ''), 'No Content') AS BodyContent,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseReasonRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pht.Name = 'Post Closed'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.BodyContent,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    (us.Upvotes - us.Downvotes) AS NetVotes,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Comments Available'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseReasonRank = 1
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.ViewCount > 10
ORDER BY 
    rp.Score DESC NULLS LAST, 
    rp.CreationDate DESC
LIMIT 100;
