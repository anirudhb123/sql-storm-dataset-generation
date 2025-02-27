WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        us.DisplayName AS Owner,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        COALESCE(cp.FirstClosedDate, 'No Closed Date') AS FirstClosedDate,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    LEFT JOIN 
        ClosedPosts cp ON rp.PostID = cp.PostId
    WHERE 
        rp.rn = 1 -- Get the latest question for each user
)

SELECT 
    PostID,
    Title,
    CreationDate,
    ViewCount,
    Score,
    Owner,
    Reputation,
    UpVotes,
    DownVotes,
    FirstClosedDate,
    CloseCount
FROM 
    FinalResults
ORDER BY 
    Score DESC
LIMIT 100;
