WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
PostRankings AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
MergedPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastActivity
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > '2023-01-01' 
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        pr.Id AS PostId,
        pr.Title,
        pr.CommentCount,
        pr.PopularityRank,
        COALESCE(mph.PostHistoryTypes, 'No Activity') AS PostHistoryDetails
    FROM 
        PostRankings pr
    LEFT JOIN 
        MergedPostHistory mph ON pr.Id = mph.PostId
    WHERE 
        pr.PopularityRank <= 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COALESCE(vs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vs.Downvotes, 0) AS TotalDownvotes,
    tp.PostId,
    tp.Title AS TopPostTitle,
    tp.CommentCount AS TopPostComments,
    tp.PopularityRank,
    tp.PostHistoryDetails,
    CASE 
        WHEN vs.TotalVotes = 0 THEN NULL
        ELSE ROUND((COALESCE(vs.Upvotes, 0)::float / vs.TotalVotes) * 100, 2)
    END AS UpvotePercentage
FROM 
    Users u
LEFT JOIN 
    UserVoteStats vs ON u.Id = vs.UserId
LEFT JOIN 
    TopPosts tp ON u.Id = tp.PostId
WHERE 
    u.Reputation > 1000 
ORDER BY 
    UpvotePercentage DESC NULLS LAST, 
    u.Reputation DESC, 
    tp.PopularityRank;

This SQL query performs a complex set of operations, including several Common Table Expressions (CTEs) that summarize user voting behavior, rank posts based on recency and comments, and aggregate post history types. It includes handling of NULL logic through the use of `COALESCE` and `CASE` statements. The query is designed for performance benchmarking by combining different SQL constructs, demonstrating an extensive use of joins, subqueries, ranking functions, and filtering predicates that explore various edge cases in the schema.
