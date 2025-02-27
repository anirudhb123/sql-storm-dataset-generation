WITH PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreCategory
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        v.CreationDate AS VoteDate,
        RANK() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    pr.PostId,
    pr.Title,
    pr.Score,
    pr.Rank,
    pr.CommentCount,
    pr.ScoreCategory,
    COALESCE(rb.BadgeCount, 0) AS UserBadgeCount,
    rb.BadgeNames,
    COALESCE(rv.VoteTypeId, 'No Recent Votes') AS RecentVoteType,
    rv.VoteDate AS RecentVoteDate,
    phs.HistoryCount AS PostHistoryCount,
    MAX(CASE WHEN phs.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
    MAX(CASE WHEN phs.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened
FROM 
    PostRankings pr
LEFT JOIN 
    UserBadges rb ON pr.PostId = rb.UserId
LEFT JOIN 
    RecentVotes rv ON pr.PostId = rv.PostId AND rv.VoteRank = 1
LEFT JOIN 
    PostHistoryStats phs ON pr.PostId = phs.PostId
WHERE 
    pr.Rank <= 5 
    AND pr.CommentCount > 0 
    AND pr.Score IS NOT NULL 
ORDER BY 
    pr.Score DESC, pr.Rank;
