
WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uvc.VoteCount, 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        UserVoteCounts uvc ON u.Id = uvc.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        @row_number := IF(@post_type_id = p.PostTypeId, @row_number + 1, 1) AS PopularityRank,
        @post_type_id := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    CROSS JOIN 
        (SELECT @row_number := 0, @post_type_id := 0) AS vars
    WHERE 
        p.CreationDate > (NOW() - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PopularityRank,
        CASE 
            WHEN ps.PopularityRank <= 5 THEN 'Top'
            ELSE 'Other'
        END AS Category
    FROM 
        PostStatistics ps
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalVotes,
    tp.Title AS TopPostTitle,
    tp.Category,
    ps.CommentCount,
    ps.TotalBounty
FROM 
    UserReputations ur
LEFT JOIN 
    TopPosts tp ON ur.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    PostStatistics ps ON tp.PostId = ps.PostId
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.Reputation DESC, tp.PopularityRank
LIMIT 10;
