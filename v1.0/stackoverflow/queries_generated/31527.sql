WITH RecursiveVoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        PostId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        RecursiveVoteCounts rv ON p.Id = rv.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
)
SELECT 
    rp.Title,
    rp.RecentVoteCount,
    ur.Reputation,
    ur.ReputationRank,
    CASE 
        WHEN rp.RecentVoteCount = 0 THEN 'No Votes Yet'
        WHEN rp.RecentVoteCount > 10 THEN 'Popular Post'
        ELSE 'Moderately Active'
    END AS ActivityStatus
FROM 
    RecentPosts rp
INNER JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.RecentVoteCount > 0
ORDER BY 
    ur.Reputation DESC, 
    rp.RecentVoteCount DESC
LIMIT 20;

-- Additionally, this section gathers post history information for those posts.
SELECT 
    p.Id AS PostId,
    ph.UserDisplayName,
    ph.CreationDate AS HistoryDate,
    p.Title,
    ph.Comment
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (1, 2, 4, 10, 12) -- Initial Title, Initial Body, Edit Title, Post Closed, Post Deleted
AND 
    p.Id IN (SELECT rp.Id FROM RecentPosts rp WHERE rp.RecentVoteCount > 0)
ORDER BY 
    p.Id, 
    ph.CreationDate DESC;

-- Finally, this part aggregates the tags assigned to these popular posts, if applicable.
SELECT 
    p.Title,
    t.TagName,
    COUNT(t.Id) AS TagCount
FROM 
    Posts p
JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- This assumes Tags are stored in a format like 'tag1,tag2'
WHERE 
    p.Id IN (SELECT rp.Id FROM RecentPosts rp WHERE rp.RecentVoteCount > 10)
GROUP BY 
    p.Title, t.TagName
ORDER BY 
    TagCount DESC;
