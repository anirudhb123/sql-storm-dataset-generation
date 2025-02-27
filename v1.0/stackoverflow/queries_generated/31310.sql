WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
    AND 
        p.Score > 5 -- Only consider posts with a score greater than 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(voteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(voteCounts.DownVotes, 0) AS DownVotes,
        COALESCE(comCounts.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) voteCounts ON p.Id = voteCounts.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId) comCounts ON p.Id = comCounts.PostId
)
SELECT 
    up.DisplayName AS UserName,
    bp.PostId,
    bp.Title,
    bp.Score,
    ub.TotalBadges,
    ub.GoldBadges,
    COALESCE(rp.Rank, 0) AS UserRank,
    rph.CloseDate,
    rph.ReopenDate,
    pi.UpVotes,
    pi.DownVotes,
    pi.CommentCount
FROM 
    RankedPosts rp
INNER JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
LEFT JOIN 
    PostInteractions pi ON rp.PostId = pi.PostId
WHERE 
    up.Reputation > 1000 -- Focus on users with a reputation over 1000
ORDER BY 
    rp.Rank, pi.UpVotes DESC;
