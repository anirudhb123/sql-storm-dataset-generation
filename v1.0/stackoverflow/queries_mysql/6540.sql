
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        @rank := IF(@prev_post_type_id = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%'),
        (SELECT @prev_post_type_id := NULL, @rank := 0) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.BadgeCount,
    phs.EditCount,
    phs.LastEditDate,
    rp.Tags
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId) 
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
