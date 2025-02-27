WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PopularTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY Tags
    HAVING COUNT(*) > 5
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    WHERE CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY PostId
)
SELECT 
    u.UserId,
    u.Reputation,
    ut.ReputationRank,
    p.Title,
    p.Tags,
    pt.Name AS PostType,
    (CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
     END) AS Status,
    COALESCE(v.VoteCount, 0) AS RecentVoteCount,
    COALESCE(v.UpVotes, 0) AS UpVoteCount,
    COALESCE(v.DownVotes, 0) AS DownVoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS PopularTagsList
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN UserReputation ut ON u.Id = ut.UserId
LEFT JOIN RecentVotes v ON p.Id = v.PostId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN PopularTags t ON p.Tags ILIKE '%' || t.Tags || '%'
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY u.UserId, ut.ReputationRank, p.Title, p.Tags, pt.Name, p.ClosedDate, v.VoteCount, v.UpVotes, v.DownVotes
ORDER BY ut.ReputationRank, p.Title;
