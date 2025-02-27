WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(vote.VoteTypeId IN (2)) OVER (PARTITION BY u.Id), 0) AS TotalUpVotes,
        COALESCE(SUM(vote.VoteTypeId IN (3)) OVER (PARTITION BY u.Id), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes vote ON vote.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(pr.Prev_Views, 0) AS PrevViewCount,
        (p.ViewCount - COALESCE(pr.Prev_Views, 0)) AS ViewIncrease,
        CASE 
            WHEN p.ViewCount - COALESCE(pr.Prev_Views, 0) > 0 THEN 'Increased'
            WHEN p.ViewCount - COALESCE(pr.Prev_Views, 0) < 0 THEN 'Decreased'
            ELSE 'No Change'
        END AS ViewChange
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            ViewCount AS Prev_Views
        FROM 
            Posts
        WHERE 
            CreationDate < CURRENT_DATE - INTERVAL '30 days'
    ) pr ON pr.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes
    FROM 
        UserStats us
    ORDER BY 
        us.Reputation DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount AS CurrentViews,
    rp.PrevViewCount,
    rp.ViewIncrease,
    rp.ViewChange,
    tuv.DisplayName AS TopUser,
    tuv.TotalUpVotes,
    tuv.TotalDownVotes
FROM 
    RecentPosts rp
CROSS JOIN 
    TopUsers tuv
WHERE 
    rp.PostTypeId IN (1, 2) -- Only Questions (1) and Answers (2)
    AND rp.ViewChange = 'Increased'
    AND (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = rp.PostId) > 5  -- Only include posts with more than 5 comments
ORDER BY 
    rp.ViewIncrease DESC, rp.ViewCount DESC;

-- Cleanup temporary structures if needed (not commonly supported in all SQL dialects)

