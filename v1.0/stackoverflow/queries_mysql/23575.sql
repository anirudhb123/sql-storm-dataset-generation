
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        CASE 
            WHEN p.CreationDate < '2024-10-01 12:34:56' - INTERVAL 1 YEAR THEN 'Old Post'
            ELSE 'Recent Post'
        END AS PostAgeCategory,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS TagName
         FROM Posts p
         INNER JOIN (
           SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1
        ) t ON true
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type_id := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.PostTypeId
), 
PostVoteCounts AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COUNT(*) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        u.Id, b.Name
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name) AS HistoryTypes,
        MAX(ph.CreationDate) AS LastActionDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rpc.UpVotes,
    rpc.DownVotes,
    rp.ViewCount,
    rp.PostAgeCategory,
    rp.Rank,
    COALESCE(badge_info.BadgeName, 'No Badges') AS RecentBadge,
    ph.HistoryTypes,
    ph.LastActionDate,
    ph.ClosedCount 
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts rpc ON rp.PostId = rpc.PostId
LEFT JOIN 
    RecentBadges badge_info ON badge_info.UserId = rp.PostId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    ph.LastActionDate DESC;
