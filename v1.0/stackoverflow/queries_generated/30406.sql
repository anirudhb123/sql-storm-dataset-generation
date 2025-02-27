WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of Posts
    SELECT 
        Id,
        ParentId,
        Title,
        PostTypeId,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.PostTypeId,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVoteDetails AS (
    -- CTE to get votes and their types for each post
    SELECT 
        postId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    -- CTE to aggregate badges earned by users for additional context
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    -- Final CTE to gather posts along with relevant data
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(pvd.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pvd.DownVotes, 0) AS TotalDownVotes,
        rph.Level,
        ub.BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteDetails pvd ON p.Id = pvd.PostId
    LEFT JOIN 
        UserBadges ub ON p.OwnerUserId = ub.UserId
    LEFT JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 100
    ORDER BY 
        TotalUpVotes DESC, 
        Score DESC
)
-- Selecting post details with ranking based on votes and scores
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.Level,
    pd.BadgeCount,
    RANK() OVER (ORDER BY pd.TotalUpVotes DESC) AS RankByUpVotes,
    DENSE_RANK() OVER (ORDER BY pd.Score DESC) AS DenseRankByScore
FROM 
    PostDetails pd
WHERE 
    pd.BadgeCount > 0 -- Only show posts from users with badges
ORDER BY 
    pd.Level, pd.Score DESC;
