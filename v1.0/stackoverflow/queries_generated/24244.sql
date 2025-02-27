WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(MAX(v.Score), 0) AS HighestVote,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- UpMod votes
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
),
ActiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 AND 
        u.LastAccessDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.HighestVote,
    COALESCE(cp.ClosedDate, 'No Closure') AS ClosureDate,
    cp.CloseReason AS ClosureReason,
    aus.UserId,
    aus.DisplayName AS ActiveUserName,
    aus.PopularPostCount,
    aus.GoldBadges,
    aus.SilverBadges,
    aus.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.ClosureRank = 1
JOIN 
    ActiveUserStats aus ON rp.OwnerUserId = aus.UserId
WHERE 
    (rp.AnswerCount > 5 OR rp.HighestVote > 10) AND 
    rp.OwnerPostRank <= 3
ORDER BY 
    rp.CreationDate DESC, 
    aus.PopularPostCount DESC 
LIMIT 100
OFFSET 0;
