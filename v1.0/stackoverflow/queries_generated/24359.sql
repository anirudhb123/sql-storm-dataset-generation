WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId BETWEEN 10 AND 20 THEN 1 END) AS ModerationActions
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.RankByScore,
    us.DisplayName AS UserDisplayName,
    us.PostsCount,
    us.GoldBadges,
    ph.LastEdited,
    ph.CloseCount,
    ph.DeleteCount,
    ph.ModerationActions,
    CASE
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    rp.UpVotes - rp.DownVotes AS NetVotes,
    COALESCE(NULLIF(rp.UpVotes + rp.DownVotes, 0), 1) AS TotalVotesNormalised,
    CASE 
        WHEN rp.Score > ALL (SELECT Score FROM Posts WHERE Score IS NOT NULL) THEN 'Top Scorer'
        ELSE 'Regular Score'
    END AS ScoreQualification
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    PostHistoryAnalysis ph ON rp.PostId = ph.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, us.PostsCount DESC;
