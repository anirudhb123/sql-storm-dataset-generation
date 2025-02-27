WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created within the last year
    GROUP BY 
        p.Id
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 3 -- Users with more than 3 badges
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.ScoreRank,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.ViewCount > 100 AND rp.Score > 10 -- Joining on some predicates
WHERE 
    rp.ScoreRank = 1 -- Only the highest score per owner user
ORDER BY 
    rp.CreationDate DESC
LIMIT 50; -- Limit to top 50 posts
