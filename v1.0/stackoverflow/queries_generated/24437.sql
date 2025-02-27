WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Only Upvotes and Downvotes
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerUserId,
        CASE 
            WHEN ph.LastClosedDate IS NOT NULL THEN 'Closed'
            WHEN ph.LastReopenedDate IS NOT NULL THEN 'Reopened'
            ELSE 'Active'
        END AS PostStatus,
        rp.RankByScore,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE 
        rp.RankByScore <= 3 -- Top 3 posts by score for each user
)
SELECT 
    f.OwnerUserId,
    COUNT(*) AS PostCount,
    SUM(CASE WHEN f.PostStatus = 'Closed' THEN 1 ELSE 0 END) AS ClosedPostCount,
    SUM(f.ViewCount) AS TotalViews,
    STRING_AGG(f.Title, '; ') AS TopPostTitles
FROM 
    FilteredPosts f
GROUP BY 
    f.OwnerUserId
ORDER BY 
    TotalViews DESC
LIMIT 10;

-- A subquery to showcase the users with the most posts, including a bizarre twist
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.Name, 'No Badge') AS Badge,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
    (SELECT MAX(ph.CreationDate) FROM PostHistory ph WHERE ph.UserId = u.Id) AS LastActivityDate,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges WHERE UserId = u.Id AND Class = 1) THEN 'Gold'
        ELSE 'No Gold'
    END AS GoldBadgePresence
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    TotalPosts DESC
LIMIT 5;

