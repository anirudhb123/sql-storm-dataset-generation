
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.ParentId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24) THEN 1 END) AS EditSuggestionsCount
    FROM PostHistory ph
    WHERE ph.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH)
    GROUP BY ph.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    ur.TotalBadges,
    phd.LastChangeDate,
    phd.ClosureCount,
    phd.EditSuggestionsCount,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN phd.ClosureCount > 0 THEN 'Closed'
        WHEN phd.EditSuggestionsCount > 0 THEN 'Under Edit Suggestion Review'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.RankByViews = 1 THEN 'Most Viewed'
        WHEN rp.RankByScore = 1 THEN 'Top Scored'
        ELSE 'Regular Post'
    END AS PostCategory,
    GROUP_CONCAT(CONCAT('Tag: ', t.TagName) SEPARATOR ', ') AS Tags
FROM RankedPosts rp
JOIN UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN PostHistoryDetail phd ON phd.PostId = rp.PostId
LEFT JOIN PostVoteStats pvs ON pvs.PostId = rp.PostId
LEFT JOIN (
    SELECT 
        DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName
    FROM (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
) AS t ON t.PostId = rp.PostId
WHERE 
    ur.Reputation >= 100 AND
    (pvs.UpVotes - pvs.DownVotes) > 5
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, 
    ur.Reputation, ur.TotalBadges, 
    phd.LastChangeDate, phd.ClosureCount, phd.EditSuggestionsCount,
    pvs.UpVotes, pvs.DownVotes, rp.RankByViews, rp.RankByScore
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
LIMIT 100;
