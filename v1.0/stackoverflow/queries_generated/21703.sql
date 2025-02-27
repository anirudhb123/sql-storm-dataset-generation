WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Considering Bounties
    WHERE 
        u.Reputation > 0 -- Only regular users
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.PostCount,
        ue.TotalCommentScore,
        ue.TotalBounty,
        CASE 
            WHEN ue.PostCount > 10 AND ue.TotalCommentScore > 50 THEN 'High Engagement'
            WHEN ue.PostCount > 5 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        UserEngagement ue
    WHERE 
        ue.EngagementRank <= 10 -- Top 10 users
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Comment, 'No edits') AS EditHistory,
        COALESCE(SUBSTRING(p.Body, 1, 200), 'No content') AS Snippet,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE()) -- Posts created in the last 2 years
),
FinalReport AS (
    SELECT 
        tu.UserId,
        tu.PostCount,
        tu.TotalCommentScore,
        tu.TotalBounty,
        tu.EngagementLevel,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.EditHistory,
        ps.Snippet,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount
    FROM 
        TopUsers tu
    INNER JOIN 
        PostSummary ps ON tu.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = ps.PostId)
)

SELECT 
    fr.*,
    COALESCE(CASE WHEN fr.UpVoteCount IS NULL THEN 'No Upvotes' ELSE CAST(fr.UpVoteCount AS VARCHAR) END, '0') AS UpVoteStatus,
    COALESCE(CASE WHEN fr.DownVoteCount IS NULL THEN 'No Downvotes' ELSE CAST(fr.DownVoteCount AS VARCHAR) END, '0') AS DownVoteStatus
FROM 
    FinalReport fr
ORDER BY 
    fr.EngagementLevel DESC, fr.TotalBounty DESC;

### Explanation
- This query computes user engagement metrics through various subqueries, utilizing CTEs for better organization.
- The `UserEngagement` CTE aggregates data on users based on their post and comment interactions, defining rankings.
- The `TopUsers` CTE categorizes users into engagement levels based on post activity and comment scores.
- The `PostSummary` CTE summarizes individual post details, including comment and vote counts.
- The `FinalReport` CTE combines user engagement levels with post details.
- The final SELECT statement provides a comprehensive view of each top user's engagement alongside their top posts, with handling for NULL values on upvotes and downvotes.
