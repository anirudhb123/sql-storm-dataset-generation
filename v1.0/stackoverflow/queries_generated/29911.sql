WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(comm.Id) AS CommentCount,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments comm ON p.Id = comm.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score
), FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(b.Id) > 1  -- Users with more than 1 badge
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.ViewCount,
        rp.Score,
        fu.UserId,
        fu.DisplayName,
        fu.Reputation
    FROM 
        RankedPosts rp
    INNER JOIN 
        FilteredUsers fu ON rp.OwnerUserId = fu.UserId
    WHERE 
        rp.RankByScore <= 5  -- Get top 5 posts per user
)
SELECT 
    tp.Title,
    tp.CommentCount,
    tp.ViewCount,
    tp.Score,
    tp.DisplayName,
    tp.Reputation
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;

-- This query benchmarks string processing by evaluating interactions 
-- between posts and their owners, filtering by user badges, 
-- effectively focusing on the top-performing questions by various 
-- criteria, thus allowing for performance evaluations on string operations.
