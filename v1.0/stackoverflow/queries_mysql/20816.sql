
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @rank := IF(@prev_post_type = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM Posts p, (SELECT @rank := 0, @prev_post_type := NULL) AS vars
    WHERE p.Score IS NOT NULL
    ORDER BY p.PostTypeId, p.Score DESC, p.CreationDate DESC
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        GROUP_CONCAT(CONCAT(ph.UserDisplayName, ' - ', ph.Comment) SEPARATOR '; ') AS Comments
    FROM PostHistory ph
    WHERE ph.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.UserId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ua.TotalVotes,
    ua.Upvotes,
    ua.Downvotes,
    ua.BadgesCount,
    phd.Comments,
    CASE 
        WHEN ua.TotalVotes IS NULL OR ua.TotalVotes = 0 THEN 'No Activity'
        WHEN ua.Upvotes > ua.Downvotes THEN 'Positive Activity'
        WHEN ua.Upvotes < ua.Downvotes THEN 'Negative Activity'
        ELSE 'Neutral Activity'
    END AS UserActivityStatus
FROM RankedPosts rp
LEFT JOIN UserActivities ua ON EXISTS (
    SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.UserId = ua.UserId
)
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
