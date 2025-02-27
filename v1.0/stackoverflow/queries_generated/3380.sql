WITH PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) as TotalVotes
    FROM Votes
    GROUP BY PostId
),
UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation > 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN Users u ON ph.UserId = u.Id
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount
    FROM Posts p
)
SELECT 
    pt.PostId,
    pt.Title,
    pt.Tags,
    pt.TagCount,
    u.ReputationLevel,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    cp.ClosedBy,
    cp.ClosedDate
FROM PostsWithTags pt
LEFT JOIN UserReputation u ON pt.PostId = u.Id
LEFT JOIN PostVoteCounts v ON pt.PostId = v.PostId
LEFT JOIN Comments c ON pt.PostId = c.PostId
LEFT JOIN ClosedPosts cp ON pt.PostId = cp.Id
WHERE 
    pt.TagCount > 3
    AND (v.TotalVotes IS NULL OR v.TotalVotes > 5)
GROUP BY 
    pt.PostId, pt.Title, pt.Tags, pt.TagCount, u.ReputationLevel, cp.ClosedBy, cp.ClosedDate
ORDER BY 
    pt.TagCount DESC, u.ReputationLevel ASC, pt.Title
LIMIT 100;
