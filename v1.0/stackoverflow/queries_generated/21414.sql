WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rb.Name AS BadgeName,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId) 
    LEFT JOIN 
        Users u ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT * FROM Badges WHERE Class = 1) rb ON rb.UserId = u.Id
    WHERE 
        rp.RN = 1
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.ViewCount,
    pwb.Score,
    COALESCE(pch.LastCloseDate, 'No close history') AS LastCloseDate,
    CASE 
        WHEN pwb.Score > 10 AND pwb.ViewCount < 50 THEN 'Needs More Attention'
        WHEN pwb.Score <= 10 AND pwb.ViewCount >= 50 THEN 'Popular but Low Quality'
        ELSE 'Normal Post'
    END AS PostQuality,
    STRING_AGG(DISTINCT 'Badge: ' || pwb.BadgeName, ', ') AS Badges
FROM 
    PostWithBadges pwb
LEFT JOIN 
    ClosedPostHistory pch ON pwb.PostId = pch.PostId
GROUP BY 
    pwb.PostId, pwb.Title, pwb.ViewCount, pwb.Score, pch.LastCloseDate
ORDER BY 
    pwb.Score DESC, pwb.ViewCount DESC
LIMIT 100;

