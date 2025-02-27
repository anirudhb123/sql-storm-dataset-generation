WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS TotalUpVotes,  -- Count of upvotes
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS TotalDownVotes   -- Count of downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COALESCE(SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalPostEdits
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostScoreAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        ue.UserId,
        ue.TotalComments,
        ue.TotalBadges,
        ue.TotalPostEdits,
        (rp.TotalUpVotes - rp.TotalDownVotes) AS EngagementScore,
        CASE 
            WHEN (rp.TotalUpVotes - rp.TotalDownVotes) >= 10 
                THEN 'High Engagement'
            WHEN (rp.TotalUpVotes - rp.TotalDownVotes) BETWEEN 5 AND 9 
                THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        UserEngagement ue ON rp.PostId = ue.UserId
    WHERE 
        rp.RankByScore = 1  -- Only select top-ranked posts
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.EngagementScore,
    ps.EngagementLevel,
    CASE 
        WHEN ps.TotalComments > 5 THEN 'Active User'
        ELSE 'New or Inactive User'
    END AS UserActivityStatus
FROM 
    PostScoreAnalysis ps
WHERE 
    ps.EngagementLevel = 'High Engagement'
ORDER BY 
    ps.EngagementScore DESC,
    ps.CreationDate ASC
LIMIT 10;

-- Additional filtering based on temporal predicates and null logic
-- Selecting only posts with no accepted answers
SELECT *
FROM Posts
WHERE AcceptedAnswerId IS NULL
AND LastActivityDate < NOW() - INTERVAL '6 months'
AND EXISTS (
    SELECT 1 
    FROM Votes v 
    WHERE v.PostId = Posts.Id AND v.VoteTypeId = 2
) 
ORDER BY CreationDate DESC;
