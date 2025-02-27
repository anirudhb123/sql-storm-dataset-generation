WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        us.Reputation,
        us.Upvotes,
        us.Downvotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.AcceptedAnswerId = u.Id
    JOIN 
        UserStats us ON u.Id = us.UserId
    WHERE 
        rp.rn = 1
),
TopClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(tc.CloseCount, 0) AS CloseCount,
    tc.LastClosedDate
FROM 
    RecentPosts rp
LEFT JOIN 
    TopClosedPosts tc ON rp.PostId = tc.PostId
WHERE 
    rp.Score > 0
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC, 
    rp.Reputation DESC
LIMIT 50;
