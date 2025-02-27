WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, Rank, VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        COUNT(c.Id) AS CommentsCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN 1 ELSE 0 END) AS IsReopened,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.PostsCount,
    ur.CommentsCount,
    ur.TotalBadges,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    phd.IsClosed,
    phd.IsReopened,
    phd.HistoryCount
FROM 
    UserActivity ur
JOIN 
    TopRankedPosts tp ON ur.PostsCount > 0
LEFT JOIN 
    PostHistoryData phd ON tp.PostId = phd.PostId
ORDER BY 
    ur.TotalBadges DESC, tp.Score DESC;
