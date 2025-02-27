WITH RECURSIVE RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.Score, 0) DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        pp.Id,
        pp.Title,
        pp.CreationDate,
        COALESCE(pp.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY pp.OwnerUserId ORDER BY COALESCE(pp.Score, 0) DESC) AS RankByScore
    FROM 
        Posts pp
    INNER JOIN 
        PostLinks pl ON pp.Id = pl.RelatedPostId
    WHERE 
        pl.PostId IN (SELECT PostId FROM RankedPosts)
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    pr.RankByScore,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS GlobalRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions only
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RankedPosts pr ON p.Id = pr.PostId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, pr.RankByScore
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    GlobalRank,
    u.DisplayName;

-- Performance benchmarking for complex logical conditions
WITH PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(CASE WHEN VoteTypeId NOT IN (3, 4) THEN 1 END) AS ValidVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(vs.TotalUpvotes, 0) AS TotalUpvotes,
        COALESCE(vs.TotalDownvotes, 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteStats vs ON p.Id = vs.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    ups.TotalUpvotes - ups.TotalDownvotes AS NetScore
FROM 
    UserPostStats ups
WHERE 
    ups.TotalPosts > 10 AND ups.TotalUpvotes IS NOT NULL
ORDER BY 
    NetScore DESC, 
    ups.DisplayName;
