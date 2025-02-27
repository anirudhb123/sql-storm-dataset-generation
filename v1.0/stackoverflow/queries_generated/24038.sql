WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT STRING_AGG(DISTINCT tag.TagName, ', ') 
                  FROM Tags tag 
                  WHERE tag.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int[])), 
                  'No Tags') AS TagList
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment, 
        ph.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes C ON ph.Comment::int = C.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.TagList,
    cp.CloseDate,
    cp.CloseReason,
    u.BadgeCount,
    u.GoldBadges,
    tu.UserRank,
    tu.DisplayName AS TopUser
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UsersWithBadges u ON u.UserId = rp.PostId -- assuming PostId is the OwnerUserId in your context
LEFT JOIN 
    TopUsers tu ON u.UserId = tu.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
WITH ORDINALITY;

-- This query showcases the ranking of the top 5 posts in each category (by score) within the last year,\
-- along with their tags, closure reason, and data of users with badges. Users are also ranked by reputation.
