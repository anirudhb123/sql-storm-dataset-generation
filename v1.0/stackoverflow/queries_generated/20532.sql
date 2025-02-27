WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '365 days'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
        JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        p.Id
),
PostHistoryActions AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ROUND(EXTRACT(EPOCH FROM (NOW() - ph.CreationDate)) / 86400.0) AS DaysSinceAction,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    up.TotalPosts,
    COALESCE(pv.UpVotes, 0) - COALESCE(pv.DownVotes, 0) AS NetVotes,
    rb.BadgeCount,
    pt.Tags,
    pha.DaysSinceAction,
    CASE 
        WHEN pha.PostHistoryTypeId IS NULL THEN 'No recent action'
        WHEN pha.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN pha.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN pha.PostHistoryTypeId = 12 THEN 'Deleted'
    END AS MostRecentAction
FROM 
    Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN PostTags pt ON rp.PostId = pt.PostId
    LEFT JOIN PostHistoryActions pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankScore <= 3 -- Top 3 posts by score for each user
    AND rp.TotalPosts > 5 -- Only users with more than 5 total posts 
ORDER BY 
    u.Reputation DESC, 
    NetVotes DESC NULLS LAST;
