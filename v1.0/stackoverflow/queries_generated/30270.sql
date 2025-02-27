WITH RecursiveVoteStatistics AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        v.UpVotes,
        v.DownVotes,
        COALESCE(CAST(t.TagName AS varchar(50)), 'No Tags') AS TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY t.Id) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT DISTINCT UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))::varchar[]) AS TagName
               FROM Posts) t ON CONCAT('<', t.TagName, '>') = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    LEFT JOIN RecursiveVoteStatistics v ON p.Id = v.PostId
),
FilteredPosts AS (
    SELECT
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.OwnerDisplayName,
        pd.TagName,
        pd.UpVotes,
        pd.DownVotes
    FROM PostDetails pd
    WHERE pd.TagRank = 1  -- Take only the first tag for each post
      AND (pd.UpVotes - pd.DownVotes) > 10 -- Only considering posts with significant net positive votes
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.TagName,
    fp.UpVotes,
    fp.DownVotes,
    CASE
        WHEN fp.UpVotes IS NULL THEN 'No Upvotes'
        WHEN fp.DownVotes IS NULL THEN 'No Downvotes'
        ELSE 'Votes accounted'
    END AS VoteStatus,
    DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', fp.CreationDate) AS PostAge
FROM FilteredPosts fp
ORDER BY fp.UpVotes DESC, fp.CreationDate DESC
LIMIT 100;

-- Additional benchmarking on posts with a specific close reason
WITH CloseReasonStats AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(CAST(cr.Name AS varchar), ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10  -- Close reasons
    GROUP BY ph.PostId
)
SELECT
    fp.*,
    crs.CloseReasonCount,
    crs.CloseReasons
FROM FilteredPosts fp
LEFT JOIN CloseReasonStats crs ON fp.PostId = crs.PostId
WHERE crs.CloseReasonCount IS NOT NULL
ORDER BY crs.CloseReasonCount DESC
LIMIT 50;
