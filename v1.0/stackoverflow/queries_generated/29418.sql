WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
BadgedUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
    HAVING 
        COUNT(*) > 5 -- Users with more than 5 badges
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.ViewCount,
        bu.BadgeCount
    FROM 
        Users u
    JOIN 
        BadgedUsers bu ON u.Id = bu.UserId
    WHERE 
        u.Reputation > 1000 -- Users with reputation greater than 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation,
    tu.BadgeCount AS TopUserBadgeCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.RowNum <= 3 -- Top 3 recent questions per user
ORDER BY 
    rp.CreationDate DESC;
