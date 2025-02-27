WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        rp.PostRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Reputation AS OwnerReputation,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    phs.EditCount,
    phs.LastEditDate,
    ru.QuestionsCreated
FROM 
    TopPosts tp
JOIN 
    PostHistoryStats phs ON tp.PostId = phs.PostId
JOIN 
    RecentUsers ru ON tp.OwnerUserId = ru.UserId
WHERE 
    tp.Score >= 10 -- Only consider top scored posts
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;

-- This query benchmarks the performance of retrieving the top posts, their edit history, 
-- and user activity in the last 30 days, showcasing various SQL concepts such as CTEs, 
-- window functions, outer joins, grouping, and filtering.
