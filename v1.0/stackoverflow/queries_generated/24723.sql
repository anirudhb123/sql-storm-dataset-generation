WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 AND 
        b.Date >= NOW() - INTERVAL '2 years'
    GROUP BY 
        b.UserId
), 
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
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
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(bc.BadgeCount, 0) AS GoldBadges,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(vs.TotalVotes, 0) AS NetVotes,
    CASE 
        WHEN cp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgeCounts bc ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bc.UserId)
LEFT JOIN 
    VotesSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 3 OR 
    (rp.CommentCount > 0 AND cp.FirstClosedDate IS NULL)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

WITH PostTagCounts AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    GROUP BY 
        1
)
SELECT 
    pt.Tag,
    pt.UsageCount,
    CASE 
        WHEN pt.UsageCount > 100 THEN 'Popular'
        WHEN pt.UsageCount BETWEEN 51 AND 100 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    PostTagCounts pt
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Tags LIKE '%' || pt.Tag || '%'
    )
ORDER BY 
    pt.UsageCount DESC;

SELECT 
    'Post: ' || p.Title || ' has been edited ' ||
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) || ' times.' AS EditSummary
FROM 
    Posts p
WHERE 
    EXISTS (
        SELECT 1 
        FROM PostHistory ph 
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5)
    )
ORDER BY 
    p.CreationDate ASC
LIMIT 5;
