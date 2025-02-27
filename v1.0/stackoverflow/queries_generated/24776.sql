WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p 
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN (
            SELECT 
                PostId,
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
            FROM 
                Votes 
            GROUP BY 
                PostId
        ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
InactiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate < CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) = 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        COUNT(DISTINCT ph.Id) AS CloseCount
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id  -- assuming 'Comment' contains the CloseReasonId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostType,
        rp.UpVotes,
        rp.DownVotes,
        rp.ViewCount,
        cu.CloseReasons,
        cu.CloseCount,
        iu.DisplayName AS InactiveUserName
    FROM 
        RankedPosts rp
    LEFT JOIN ClosedPosts cu ON rp.PostId = cu.PostId
    LEFT JOIN InactiveUsers iu ON rp.PostId = iu.UserId
)

SELECT 
    PostId, 
    Title, 
    PostType, 
    UpVotes, 
    DownVotes, 
    ViewCount,
    COALESCE(CloseReasons, 'No Close Reasons') AS CloseReasons,
    COALESCE(CAST(CloseCount AS VARCHAR), '0') AS CloseCount,
    CASE 
        WHEN UpVotes > DownVotes THEN 'Positive Sentiment'
        WHEN DownVotes > UpVotes THEN 'Negative Sentiment'
        ELSE 'Neutral Sentiment'
    END AS Sentiment
FROM 
    FinalResults
WHERE 
    Rank <= 5
ORDER BY 
    ViewCount DESC, 
    UpVotes DESC
LIMIT 20;

This SQL query employs various advanced SQL constructs, including Common Table Expressions (CTEs), correlated subqueries, window functions, outer joins, aggregation functions, string manipulation, and conditional logic. 

- **CTEs** are used to structure the query into logical blocks - ranking posts, finding inactive users, and closed posts.
- **Window functions** rank posts and partition data accordingly.
- **Outer joins** are utilized to gather data that may not match in other tables.
- **STRING_AGG** creates a string list of close reasons for closed posts.
- **COALESCE** provides default values for NULLs, ensuring that the query returns user-friendly outputs.
- **Conditional logic** assesses the sentiment of posts based on the upvote and downvote counts. 

This query not only extracts relevant data but also encapsulates various SQL complexity levels suitable for performance benchmarking.
