WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year
), 
UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(v.VoteTypeId, 0)) AS VoteScore, -- Assumes VoteTypeId can represent a scoring mechanism
        COUNT(DISTINCT p.Id) AS TotalPosts,
        MAX(u.Reputation) AS MaxRep
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopBountyPost AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(p.Score, 0) + COALESCE(v.BountyAmount, 0) AS AdjustedScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate < DATEADD(month, -6, GETDATE()) -- Posts older than 6 months
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalSummary AS (
    SELECT
        up.UserId,
        up.DisplayName,
        us.TotalBounties,
        us.VoteScore,
        us.TotalPosts,
        phs.CloseOpenCount,
        phs.DeletionCount,
        r.Title,
        r.CreationDate
    FROM 
        UserScoreSummary us
    JOIN 
        Users up ON up.Id = us.UserId
    LEFT JOIN 
        RankedPosts r ON up.Id = r.OwnerUserId AND r.RankScore <= 1
    LEFT JOIN 
        PostHistorySummary phs ON r.PostId = phs.PostId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.TotalBounties,
    f.VoteScore,
    f.TotalPosts,
    f.CloseOpenCount,
    f.DeletionCount,
    COALESCE(tbp.Title, 'No Record') AS TopBountyTitle,
    COALESCE(tbp.AdjustedScore, 0) AS TopBountyAdjustedScore
FROM 
    FinalSummary f
LEFT JOIN 
    TopBountyPost tbp ON f.UserId = tbp.OwnerUserId
ORDER BY 
    f.TotalBounties DESC, 
    f.VoteScore DESC, 
    f.TotalPosts DESC
WITH TIES; 

### Explanation:
1. **CTEs**: Created multiple Common Table Expressions (CTEs) to break down the logic into manageable sections:
   - `RankedPosts`: Collects and ranks recent questions by their score.
   - `UserScoreSummary`: Aggregates user data including total bounties earned and total posts.
   - `TopBountyPost`: Identifies posts with the highest bounty scores that are older than 6 months.
   - `PostHistorySummary`: Summarizes post histories to count closures/openings and deletions.

2. **Final Summary**: Joins user data and their ranking with summaries of their post history and top bounty posts.

3. **Main Query**: Selects the final pertinent fields, leveraging `COALESCE` to handle NULL logic, and sorts results to identify users with the highest bounties, scores, and activity.

4. **Window Functions**: Utilizes `ROW_NUMBER()` to rank posts per user strictly for scoring, reflecting both performance and engagement.

5. **Complicated logic**: Integrates conditional counting in the `PostHistorySummary` and combines results with outer joins to encompass all cases.

6. **Output**: Returns comprehensive insights into user performance regarding post creations, scores accrued, and engagement level with bounties and historical actions.

This
