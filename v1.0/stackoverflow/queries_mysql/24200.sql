
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.Body, u.Id, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        GROUP_CONCAT(cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
AggregatedUserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.UserDisplayName,
    rp.CommentCount,
    tp.TagName,
    cp.CloseReasons,
    aus.DisplayName AS TopUser,
    aus.GoldBadges,
    aus.SilverBadges,
    aus.BronzeBadges,
    aus.AvgBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    AggregatedUserStats aus ON aus.Id = (SELECT UserId FROM Users WHERE Reputation = (SELECT MAX(Reputation) FROM Users))
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CommentCount DESC, 
    rp.Title ASC
LIMIT 100;
