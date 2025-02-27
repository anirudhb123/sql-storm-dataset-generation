WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        CAST(NULL AS INT) AS ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        p.Id AS ParentId,
        Level + 1
    FROM Posts a
    INNER JOIN Posts p ON a.ParentId = p.Id
    WHERE a.PostTypeId = 2  -- Selecting Answers for the Questions
),

PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,  -- Upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,  -- Downvotes
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY p.Id
),

HighScorePosts AS (
    SELECT
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.TotalVotes
    FROM RecursivePostCTE pp
    JOIN PostVoteSummary ps ON pp.PostId = ps.PostId
    WHERE pp.Score >= (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)  -- Filter for high-scoring posts
),

CombinedData AS (
    SELECT 
        h.*, 
        COALESCE(k.Tags, 'No Tags') AS Tags,
        t.Name AS PostTypeName
    FROM HighScorePosts h
    LEFT JOIN (
        SELECT 
            p.Id,
            STRING_AGG(t.TagName, ', ') AS Tags
        FROM Posts p
        CROSS JOIN LATERAL string_to_array(p.Tags, ',') AS tag
        JOIN Tags t ON t.Id = tag::int
        GROUP BY p.Id
    ) k ON h.PostId = k.Id
    LEFT JOIN PostTypes t ON t.Id = (SELECT PostTypeId FROM Posts WHERE Id = h.PostId)
)

SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.UpVotes,
    cd.DownVotes,
    cd.TotalVotes,
    cd.Tags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    RANK() OVER (PARTITION BY cd.PostTypeName ORDER BY cd.Score DESC) AS ScoreRank
FROM CombinedData cd
LEFT JOIN Comments c ON cd.PostId = c.PostId
GROUP BY cd.PostId, cd.Title, cd.CreationDate, cd.Score, cd.UpVotes, cd.DownVotes, cd.TotalVotes, cd.Tags, cd.PostTypeName
ORDER BY cd.Score DESC, ScoreRank
LIMIT 50;

