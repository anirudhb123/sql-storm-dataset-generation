WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
CloseVotes AS (
    SELECT 
        Ph.PostId, 
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId = 10 
    GROUP BY 
        Ph.PostId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        um.Reputation AS UserReputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        (SELECT Id, Reputation FROM Users) um ON u.Id = um.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    cv.CloseVoteCount,
    tu.UserId,
    tu.DisplayName,
    tu.BadgeCount,
    tu.UserReputation,
    tu.PostCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><')::int[]))) 
     AND NOT EXISTS (SELECT 1 FROM Posts WHERE OwnerUserId = tu.UserId AND CreationDate < rp.CreationDate)) AS RelevantTags
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseVotes cv ON rp.PostId = cv.PostId
LEFT JOIN 
    TopUsers tu ON rp.CreationDate < NOW() - INTERVAL '30 days' AND rp.Rank <= 10
WHERE 
    rp.Rank <= 20 
    AND ((cv.CloseVoteCount IS NOT NULL AND cv.CloseVoteCount > 0) 
         OR (tu.UserId IS NOT NULL AND tu.UserReputation > 1000))
ORDER BY 
    rp.Rank, 
    rp.ViewCount DESC;
