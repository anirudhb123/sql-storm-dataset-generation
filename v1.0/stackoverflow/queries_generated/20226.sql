WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Tags
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
)

SELECT 
    up.UserId,
    up.Reputation,
    up.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(pt.PostCount, 0) AS PopularTagPostCount,
    CASE 
        WHEN rp.Score >= 50 THEN 'High Score'
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE 'Low Score'
    END AS Score_Category
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.Reputation >= 200
LEFT JOIN 
    PopularTags pt ON POSITION(pt.TagName IN rp.Title) > 0
WHERE 
    up.BadgeCount > 0 
    AND up.UserId IS NOT NULL
ORDER BY 
    up.Reputation DESC,
    rp.ViewCount DESC
LIMIT 100;

-- Additional complexity showcasing behaviour of NULL and IF
WITH CommunityVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS VoteBalance
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    c.UserId, 
    COUNT(cp.PostId) AS TotalPosts,
    COALESCE(cv.VoteBalance, 0) AS NetVotes
FROM 
    Users c
LEFT JOIN 
    CommunityVotes cv ON cv.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = c.Id)
JOIN 
    Posts cp ON cp.OwnerUserId = c.Id
WHERE 
    COALESCE(cv.VoteBalance, 0) >= 0 
GROUP BY 
    c.UserId
HAVING 
    TotalPosts > 5
ORDER BY 
    NetVotes DESC;

-- CTEs could also add nested complexity by incorporating complex conditions and aggregations based on timestamps.

