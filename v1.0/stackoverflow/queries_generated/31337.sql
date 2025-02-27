WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),

RecentPostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 month'
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COALESCE(ph.Comment, 'No comments') AS LastComment,
        MAX(ph.CreationDate) AS LastActivity
    FROM Posts p
    LEFT JOIN RecentPostHistories ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.Body, ph.Comment
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),

FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.LastComment,
        pd.LastActivity,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        ts.PostCount AS TagPostCount,
        ts.TotalViews AS TagTotalViews
    FROM PostDetails pd
    LEFT JOIN UserVoteCounts uv ON pd.PostId = uv.UserId
    LEFT JOIN TagStatistics ts ON pd.Title LIKE '%' || ts.TagName || '%'
    WHERE pd.LastActivity IS NOT NULL
    ORDER BY pd.LastActivity DESC
)

SELECT 
    *,
    CASE 
        WHEN UpVotes > DownVotes THEN 'Positive'
        WHEN UpVotes < DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    COALESCE(NULLIF(TotalViews, 0), 1) AS NonZeroViews  -- Avoid division by zero
FROM FinalResults
WHERE TagPostCount > 0 -- Only include posts associated with defined tags
ORDER BY NonZeroViews DESC, LastActivity DESC;
