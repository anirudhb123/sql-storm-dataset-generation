WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId, b.Name
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
)
SELECT 
    rp.Title AS PostTitle,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation,
    tu.BadgeCount AS TopUserBadgeCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.ViewRank = 1 
    AND tu.UserRank <= 10
ORDER BY 
    rp.ViewCount DESC, 
    tu.Reputation DESC;
