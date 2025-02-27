WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.Score,
        a.ParentId,
        ph.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2  -- Join with answers
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore -- Sum up badge classes as a metric
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
CombinedStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Score,
        ph.Level,
        pvs.UpVotes,
        pvs.DownVotes,
        ua.PostsCount,
        ua.BadgeScore
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        PostVoteSummary pvs ON ph.PostId = pvs.PostId
    LEFT JOIN 
        UserActivity ua ON ph.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
)

SELECT 
    cs.PostId,
    cs.Title,
    cs.Score,
    cs.Level,
    COALESCE(cs.UpVotes, 0) AS UpVotes,
    COALESCE(cs.DownVotes, 0) AS DownVotes,
    COALESCE(cs.PostsCount, 0) AS PostsCount,
    COALESCE(cs.BadgeScore, 0) AS BadgeScore,
    CASE 
        WHEN cs.Score > 10 THEN 'High'
        WHEN cs.Score BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    CombinedStats cs
ORDER BY 
    cs.Level, cs.Score DESC
LIMIT 100;
