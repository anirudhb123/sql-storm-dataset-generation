WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionsWithLinks AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(pl.RelatedPostId) AS LinksCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(ph.FirstClosedDate, 'N/A') AS FirstClosed,
    COALESCE(ph.LastReopenedDate, 'N/A') AS LastReopened,
    ph.CloseReopenCount,
    qu.LinksCount,
    bu.BadgeCount,
    CASE 
        WHEN bu.HighestBadgeClass = 1 THEN 'Gold' 
        WHEN bu.HighestBadgeClass = 2 THEN 'Silver' 
        WHEN bu.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge' 
    END AS HighestBadge
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    QuestionsWithLinks qu ON rp.PostId = qu.QuestionId
LEFT JOIN 
    BadgedUsers bu ON rp.PostId = bu.UserId
WHERE 
    rp.Rank <= 5 
    AND (
        rp.UpVotes - rp.DownVotes > 0 
        OR (rp.Score > 10 AND bu.BadgeCount > 0)
    )
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;
