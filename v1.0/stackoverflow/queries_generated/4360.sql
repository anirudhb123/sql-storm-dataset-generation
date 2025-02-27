WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.UserId IS NOT NULL), 0) AS UpvotesCount,
        COALESCE(SUM(v.UserId IS NOT NULL AND v.VoteTypeId = 1), 0) AS AcceptedCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditDate,
        p.Title AS PostTitle,
        p.Score AS PostScore,
        p.Body,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 12) -- Edit Title, Edit Body, Post Closed, Post Deleted
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    up.DisplayName,
    up.Reputation,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    phd.EditDate,
    phd.Comment,
    COUNT(DISTINCT phd.EditorId) AS EditorsCount
FROM 
    TopUsers up
JOIN 
    RankedPosts tp ON up.UserId = tp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
WHERE 
    tp.Rank = 1
GROUP BY 
    up.DisplayName, up.Reputation, tp.Title, tp.Score, phd.EditDate, phd.Comment
ORDER BY 
    up.Reputation DESC, TopPostScore DESC;
