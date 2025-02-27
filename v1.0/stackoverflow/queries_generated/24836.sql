WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.UserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByRecency,
        COUNT(v.Id) FILTER(WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER(WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.ViewCount,
        ap.UserId,
        ap.DisplayName,
        ap.Reputation,
        ap.TotalBadges,
        (SELECT COUNT(*) FROM RecentPostHistory rph WHERE rph.PostId = rp.PostId) AS RecentChanges,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers ap ON rp.UserId = ap.UserId
    WHERE 
        rp.RankByRecency <= 5
        AND (rp.ViewCount > 100 OR (rp.Score > 5 AND rp.UpVoteCount > 0))
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.ViewCount,
    fp.DisplayName,
    fp.Reputation,
    fp.TotalBadges,
    fp.RecentChanges,
    fp.PostSentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.RecentChanges DESC NULLS LAST,
    fp.ViewCount DESC
LIMIT 50;

