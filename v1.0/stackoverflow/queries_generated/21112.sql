WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 6, 10, 11) -- Edit Title, Edit Tags, Post Closed, Post Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(phc.EditCount, 0) AS TotalEdits,
    phc.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.Id = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.rn <= 3 
    AND (ub.BadgeCount > 0 OR rp.Score > 10)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, ub.BadgeCount DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional queries to benchmark performance
WITH PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
FilteredPosts AS (
    SELECT 
        p.Title,
        pvc.UpVotes,
        pvc.DownVotes,
        CASE 
            WHEN pvc.UpVotes IS NOT NULL AND pvc.DownVotes IS NOT NULL AND pvc.UpVotes > pvc.DownVotes THEN 'Positive'
            WHEN pvc.UpVotes IS NOT NULL AND pvc.DownVotes IS NOT NULL AND pvc.UpVotes < pvc.DownVotes THEN 'Negative'
            ELSE 'Undefined'
        END AS Sentiment
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts pvc ON p.Id = pvc.PostId
    WHERE 
        p.ViewCount > 100
)
SELECT 
    Title,
    UpVotes,
    DownVotes,
    Sentiment
FROM 
    FilteredPosts
WHERE 
    Sentiment = 'Positive'
ORDER BY 
    UpVotes DESC
FETCH FIRST 5 ROWS ONLY;

-- Adaptive query snippet showcasing outer join and null logic
SELECT 
    u.DisplayName,
    p.Title,
    COALESCE(cns.Count, 0) AS CommentCount,
    COUNT(COALESCE(v.Id, 0)) AS VoteCount,
    MAX(ph.CreationDate) AS LastVoteDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments cns ON p.Id = cns.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.Reputation IS NOT NULL
GROUP BY 
    u.DisplayName, p.Title
HAVING 
    COUNT(v.Id) > 5
ORDER BY 
    u.Reputation DESC;
