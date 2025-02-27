
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS RN,
        @prev_user := p.OwnerUserId,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tu.DisplayName AS Owner,
    tu.Reputation,
    tu.QuestionCount,
    pt.Tag,
    pt.TagCount,
    phs.ClosedCount,
    phs.ReopenedCount,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.Tag, REPLACE(rp.Tags, '><', ',')) 
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    rp.RN = 1 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
