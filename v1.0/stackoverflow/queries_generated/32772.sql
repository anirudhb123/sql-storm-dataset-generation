WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all parent posts
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    -- Summary of votes per post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetail AS (
    -- Joining post details along with vote summary
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(s.UpVotes, 0) AS UpVotes,
        COALESCE(s.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        (SELECT string_agg(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int)) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary s ON p.Id = s.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for the last year
    GROUP BY 
        p.Id, s.UpVotes, s.DownVotes
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.TagList,
    CASE 
        WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
        WHEN pd.UpVotes < pd.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = r.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = r.PostId) AS LinkCount
FROM 
    RecursivePostHierarchy r
JOIN 
    PostDetail pd ON r.PostId = pd.PostId
WHERE 
    r.Level = 0  -- Focus on top-level posts
ORDER BY 
    pd.UpVotes - pd.DownVotes DESC,  -- Order by net votes
    pd.CommentCount DESC;              -- Then by comments
