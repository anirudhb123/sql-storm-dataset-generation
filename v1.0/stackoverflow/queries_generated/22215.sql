WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
ActiveTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        CASE 
            WHEN COUNT(p.Id) > 10 THEN 'High Activity'
            WHEN COUNT(p.Id) BETWEEN 5 AND 10 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    us.DisplayName,
    us.BadgeCount,
    COALESCE(cph.CloseCount, 0) AS CloseCount,
    COALESCE(cph.LastClosedDate, 'No Close History') AS LastClosedDate,
    at.TagName,
    at.ActivityLevel,
    us.TotalBounty,
    us.UpVotes,
    us.DownVotes,
    RPAD('This is a post with the title ' || rp.Title || '. It was created on ' || TO_CHAR(rp.CreationDate, 'YYYY-MM-DD') || '.', 1000) AS FullDescription
FROM RankedPosts rp
JOIN Users us ON rp.OwnerUserId = us.Id
LEFT JOIN ClosedPostHistory cph ON rp.PostId = cph.PostId
JOIN ActiveTags at ON at.TagId = ANY(string_to_array(rp.Tags, ',')::int[])
WHERE rp.Rank <= 5
ORDER BY rp.ViewCount DESC, rp.Score DESC;
