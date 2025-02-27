WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS PostRankCategory
    FROM 
        RankedPosts rp
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
        LEFT JOIN Posts p ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON c.UserId = u.Id
        LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.CommentCount,
        tp.UpvoteCount,
        tp.DownvoteCount,
        us.DisplayName AS UserName,
        us.Reputation AS UserReputation,
        tp.PostRankCategory
    FROM 
        TopPosts tp
        JOIN Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
        LEFT JOIN UserStats us ON us.UserId = u.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.UpvoteCount,
    p.DownvoteCount,
    p.UserName,
    p.UserReputation,
    COALESCE(p.PostRankCategory, 'Uncategorized') AS RankCategory,
    CASE 
        WHEN p.Score > 100 THEN 'Highly Rated'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory
FROM 
    PostMetrics p
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
