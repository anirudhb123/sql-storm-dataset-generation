WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UniqueTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        p.Id AS PostId
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseOpenCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 52) AS HotCount,
        MIN(ph.CreationDate) AS FirstHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u 
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- Bounties
    GROUP BY 
        u.Id
),
FinalReport AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CommentCount,
        r.Score,
        COALESCE(u.TotalBadges, 0) AS UserBadges,
        COALESCE(u.TotalBounties, 0) AS TotalBounties,
        p.CloseOpenCount,
        p.HotCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        RankedPosts r
    LEFT JOIN UserReputation u ON r.OwnerUserId = u.UserId
    LEFT JOIN UniqueTags t ON r.PostId = t.PostId
    LEFT JOIN PostHistoryAggregate p ON r.PostId = p.PostId
    WHERE 
        r.rn = 1
    GROUP BY 
        r.PostId, r.Title, r.CommentCount, r.Score, u.TotalBadges, u.TotalBounties, p.CloseOpenCount, p.HotCount
)
SELECT * 
FROM FinalReport
WHERE 
    (UserBadges > 3 OR TotalBounties > 0)
    AND (CloseOpenCount IS NULL OR CloseOpenCount < 5)
ORDER BY 
    Score DESC, UserBadges DESC, CreationDate DESC;
