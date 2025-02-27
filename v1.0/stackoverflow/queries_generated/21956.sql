WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.CreationDate > '2022-01-01' AND v.VoteTypeId IN (2, 3)) AS RecentVotes,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseRestoreCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        JSON_AGG(DISTINCT ph.Comment) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS ClosureComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    rp.CommentCount,
    uh.UserId,
    uh.DisplayName,
    uh.TotalBounty,
    uh.RecentVotes,
    uh.MaxReputation,
    phd.InitialTitleDate,
    phd.ClosedDate,
    phd.CloseRestoreCount,
    phd.ClosureComments
FROM 
    RankedPosts rp
JOIN 
    UserScores uh ON uh.TotalBounty >= (SELECT AVG(TotalBounty) FROM UserScores) -- Users with above-average bounties
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per type based on score
    AND (phd.ClosedDate IS NULL OR phd.CloseRestoreCount > 0) -- Only includes posts that are not closed or have restored closure
ORDER BY 
    rp.PostTypeId, rp.Score DESC, uh.MaxReputation DESC;
This SQL query extracts and ranks posts while considering several factors: performance based on scores, user contributions through bounties, and the historical status of the posts regarding closures and restorations. The use of Common Table Expressions (CTEs) allows for structured subqueries that refine results step by step, demonstrating complex SQL constructs, including outer joins, window functions, GROUP BY with conditional aggregates, and JSON handling for diverse outputs.
