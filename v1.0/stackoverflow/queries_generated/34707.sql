WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts from the last year
    GROUP BY 
        p.Id
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
RecommendedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        ua.DisplayName AS OwnerDisplayName,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.CommentCount > 5 AND ua.TotalUpVotes > 10 -- filter users with significant activity
    WHERE 
        rp.ScoreRank <= 5 -- top 5 posts per type
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.OwnerDisplayName,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    rp.CommentCount,
    COALESCE(DATEDIFF(NOW(), rp.CreationDate), 'N/A') AS DaysSinceCreation
FROM 
    RecommendedPosts rp
ORDER BY 
    rp.Score DESC, 
    rp.CommentCount DESC;

