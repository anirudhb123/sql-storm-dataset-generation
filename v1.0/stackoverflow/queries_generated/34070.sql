WITH RecursivePostHierarchy AS (
    -- Generate a recursive hierarchy of posts and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Start with questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        rh.Level + 1
    FROM Posts a
    INNER JOIN RecursivePostHierarchy rh ON a.ParentId = rh.PostId
    WHERE a.PostTypeId = 2  -- Only answers
),
PostVoteSummary AS (
    -- Calculate summary for each post's votes and score
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetScore
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostTags AS (
    -- Extract tags for each post along with their counts
    SELECT 
        p.Id AS PostId,
        string_agg(distinct trim(tag.TagName), ', ') AS Tags,
        COUNT(tag.Id) AS TagCount
    FROM Posts p
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '><')) AS tag(TagName) ON TRUE 
    GROUP BY p.Id
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    pvs.NetScore,
    COALESCE(pt.Tags, 'No Tags') AS Tags,
    pt.TagCount,
    CASE 
        WHEN rph.PostTypeId = 1 THEN 'Question'
        ELSE 'Answer'
    END AS PostType,
    u.DisplayName AS OwnerName,
    COALESCE(u.Reputation, 0) AS OwnerReputation,
    COUNT(c.Id) FILTER (WHERE c.Score > 0) AS PositiveCommentCount,
    COUNT(c.Id) FILTER (WHERE c.Score < 0) AS NegativeCommentCount
FROM RecursivePostHierarchy rph
LEFT JOIN PostVoteSummary pvs ON rph.PostId = pvs.PostId
LEFT JOIN PostTags pt ON rph.PostId = pt.PostId
LEFT JOIN Users u ON rph.OwnerUserId = u.Id
LEFT JOIN Comments c ON rph.PostId = c.PostId
WHERE rph.Level <= 3 -- Limit the depth of the hierarchy
GROUP BY 
    rph.PostId, rph.Title, rph.Level, pvs.UpVotes, pvs.DownVotes, 
    pvs.TotalVotes, pvs.NetScore, pt.Tags, pt.TagCount, 
    u.DisplayName, u.Reputation
ORDER BY 
    rph.Level, rph.PostId;
