WITH RecursivePostCTE AS (
    -- Recursive CTE to fetch answers for questions and their subsequent edits
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
        
    UNION ALL 
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers only
),
PostEditHistory AS (
    -- CTE to get edit history for questions and answers
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastEdited,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedReopened
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserDisplayName, ph.CreationDate
),
UserReputation AS (
    -- CTE to calculate user reputation based on different metrics
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    -- CTE to calculate statistics for each post
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COALESCE(e.LastEdited, 'Never Edited') AS LastEdited,
        COALESCE(e.LastClosedReopened, 'Active') AS LastClosedReopened,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        PostEditHistory e ON p.Id = e.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, e.LastEdited, e.LastClosedReopened
)

SELECT 
    ps.Id AS PostId,
    ps.Title,
    ps.Score,
    ps.LastEdited,
    ps.LastClosedReopened,
    ps.CommentCount,
    ps.TotalBounties,
    ur.DisplayName AS Author,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ur.TotalBadges,
    ur.TotalPosts,
    COUNT(rp.PostId) AS AnswerCount,
    CASE 
        WHEN ps.Score > 100 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    PostStatistics ps
LEFT JOIN 
    UserReputation ur ON ps.Id = ur.UserId
LEFT JOIN 
    RecursivePostCTE rp ON ps.Id = rp.Id
GROUP BY 
    ps.Id, ps.Title, ps.Score, ps.LastEdited, ps.LastClosedReopened,
    ur.DisplayName, ur.TotalUpVotes, ur.TotalDownVotes, ur.TotalBadges, ur.TotalPosts
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC;
