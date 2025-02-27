WITH Post_Vote_Summary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
Post_Aggregated AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
        COALESCE(pvs.TotalVotes, 0) AS TotalVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS PostTags
    FROM Posts p
    LEFT JOIN Post_Vote_Summary pvs ON p.Id = pvs.PostId
    LEFT JOIN UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
Top_Posts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        TotalUpVotes,
        TotalDownVotes,
        TotalVoteCount,
        PostTags,
        RANK() OVER (ORDER BY TotalVoteCount DESC, Score DESC, ViewCount DESC) AS VoteRank
    FROM Post_Aggregated
)
SELECT 
    *,
    CASE 
        WHEN TotalVoteCount > 100 THEN 'Highly Engaged'
        WHEN TotalVoteCount BETWEEN 50 AND 100 THEN 'Moderately Engaged'
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM Top_Posts
WHERE VoteRank <= 10
ORDER BY VoteRank;
