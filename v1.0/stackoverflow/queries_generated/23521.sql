WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        h.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id 
    WHERE 
        ph.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    ph.HistoryType,
    ph.CreationDate AS HistoryDate,
    ph.UserId AS HistoryEditorId,
    CASE 
        WHEN ph.UserId IS NOT NULL THEN 'Edited'
        ELSE 'No Edits'
    END AS EditStatus
FROM 
    UsersWithBadges up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentPostHistory ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    up.BadgeCount > 0 
    AND rp.RankByScore <= 3
    AND (up.Location IS NOT NULL AND LENGTH(up.Location) > 0) 
    OR (up.Location IS NULL AND up.Reputation > 1000)
ORDER BY 
    up.BadgeCount DESC, rp.Score DESC
OFFSET 100 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation of the Query Components:
1. **CTEs (Common Table Expressions)**: 
   - **RankedPosts**: Ranks the posts by score for each user.
   - **UsersWithBadges**: Aggregates badge information for each user.
   - **RecentPostHistory**: Captures the recent post history for posts edited in the last 30 days.

2. **Window Functions**: 
   - Used to rank posts and the latest history entries.

3. **JOINs**: 
   - Inner joins to filter users who have badges along with their top-ranked posts.
   - Left joins to include information on recent edits, if applicable.

4. **CASE expressions**: 
   - To determine if a post has been edited or not based on whether there is an entry in the `RecentPostHistory`.

5. **Complicated predicates**: 
   - Filters users based on badge counts and combines location-based logic, providing a twist with NULL checks.

6. **Pagination**: 
   - Uses OFFSET and FETCH NEXT for paging results.

This structure offers a detailed performance benchmark while testing different SQL constructs.
