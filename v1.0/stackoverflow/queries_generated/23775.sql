WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COALESCE((
            SELECT 
                COUNT(c.Id)
            FROM 
                Comments c
            WHERE 
                c.PostId = p.Id
        ), 0) AS CommentsCount,
        COALESCE((
            SELECT 
                COUNT(ph.Id)
            FROM 
                PostHistory ph
            WHERE 
                ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11) -- Closing and reopening actions
        ), 0) AS CloseReopenCount,
        COALESCE((
            SELECT 
                MAX(ph.CreationDate)
            FROM 
                PostHistory ph
            WHERE 
                ph.PostId = p.Id
        ), NULL) AS LastHistoryDate
    FROM 
        Posts p
)
SELECT 
    u.DisplayName,
    p.PostId,
    p.Title,
    p.PostCreationDate,
    p.CommentsCount,
    p.CloseReopenCount,
    DATE_PART('year', p.PostCreationDate) AS PostYear,
    uv.UpVotesCount,
    uv.DownVotesCount,
    CASE 
        WHEN uv.TotalVotesCount IS NULL OR uv.TotalVotesCount = 0 THEN 'No Votes'
        WHEN uv.UpVotesCount > uv.DownVotesCount THEN 'Positive Feedback'
        WHEN uv.UpVotesCount < uv.DownVotesCount THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackStatus,
    STRING_AGG(TRY_CAST(Tags AS VARCHAR(100)) || ' (' || p.CloseReopenCount || ')', ', ') AS TagsWithCloseCount
FROM 
    UserVoteCounts uv
JOIN 
    Users u ON u.Id = uv.UserId
JOIN 
    PostDetails p ON p.PostId = (
        SELECT 
            pm.Id
        FROM 
            Posts pm
        WHERE 
            pm.OwnerUserId = u.Id
        ORDER BY 
            pm.CreationDate DESC
        LIMIT 1
    )
LEFT JOIN 
    LATERAL (
        SELECT 
            p.Tags
        FROM 
            Posts p
        WHERE 
            p.Id = p.PostId
        LIMIT 1
    ) as post_tags ON TRUE
GROUP BY 
    u.DisplayName, p.PostId, p.Title, p.PostCreationDate, p.CommentsCount, p.CloseReopenCount, uv.UpVotesCount, uv.DownVotesCount
ORDER BY 
    p.PostCreationDate DESC
LIMIT 50 OFFSET (SELECT FLOOR(RANDOM() * (SELECT COUNT(*) FROM Posts)));

This SQL query is designed to benchmark performance across various constructs in a complex way:

- **CTEs**: Two CTEs (`UserVoteCounts` and `PostDetails`) create aggregations related to user votes and post details respectively.
- **Subqueries**: Correlated subqueries are used to retrieve comment counts and close/reopen history alongside post details.
- **Outer Joins**: A left join on votes allows counting up and down votes even if a user has none.
- **Window Functions**: Utilizing `DATE_PART` for year extraction while aggregating results.
- **Case Statements**: To derive feedback status based on vote counts.
- **String Aggregation**: Collects tags along with close counts.
- **Random Sampling**: OFFSET with random value to avoid consistent offsets while testing.
- **NULL Logic**: The query handles potential NULLs effectively in multiple places (like upvote counts).

This multicomponent query involves several SQL constructs that warrant performance testing as they interact with potentially large datasets across related tables.
