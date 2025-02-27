WITH RecursivePostHierarchy AS (
    -- CTE to recursively get parent posts and their metadata
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
  
    UNION ALL
  
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),

PostStatistics AS (
    -- CTE to calculate various statistics for posts
    SELECT 
        Posts.Id,
        Posts.Title,
        COALESCE(SUM(Votes.VoteTypeId = 2), 0) AS Upvotes,  -- Count of upvotes
        COALESCE(SUM(Votes.VoteTypeId = 3), 0) AS Downvotes, -- Count of downvotes
        COALESCE(AVG(CASE WHEN Comments.Id IS NOT NULL THEN Comments.Score END), 0) AS AvgCommentScore,  -- Avg score of comments
        COUNT(DISTINCT Comments.Id) AS TotalComments,  -- Total number of comments
        ARRAY_AGG(DISTINCT Tags.TagName) AS Tags  -- Tags associated to the posts
    FROM Posts
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(Posts.Tags, '><')) AS TagName
    ) AS Tags ON TRUE
    GROUP BY Posts.Id
),

FinalResults AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ps.Upvotes,
        ps.Downvotes,
        ps.AvgCommentScore,
        ps.TotalComments,
        ph.Level AS PostLevel,
        ph.AcceptedAnswerId,
        STRING_AGG(DISTINCT CASE WHEN ht.Name IS NOT NULL THEN ht.Name END, ', ') AS HistoryTypes
    FROM Posts p
    JOIN PostStatistics ps ON p.Id = ps.Id
    LEFT JOIN RecursivePostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN PostHistory phis ON p.Id = phis.PostId
    LEFT JOIN PostHistoryTypes ht ON phis.PostHistoryTypeId = ht.Id
    GROUP BY 
        p.Id, ps.Upvotes, ps.Downvotes, ps.AvgCommentScore, 
        ps.TotalComments, ph.Level, ph.AcceptedAnswerId
    ORDER BY p.ViewCount DESC
    LIMIT 10
)

SELECT 
    Title,
    CreationDate,
    ViewCount,
    Score,
    Upvotes,
    Downvotes,
    AvgCommentScore,
    TotalComments,
    PostLevel,
    AcceptedAnswerId,
    COALESCE(HistoryTypes, 'No history found') AS HistoryTypes
FROM FinalResults;
