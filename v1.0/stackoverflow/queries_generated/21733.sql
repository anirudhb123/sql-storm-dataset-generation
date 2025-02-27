WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (1, 2) THEN 1 ELSE 0 END), 0) AS TotalPositiveVotes,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        AVG(COALESCE(vs.VoteScore, 0)) AS AveragePostScore,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN u.Reputation >= 1000 THEN 'Established' 
            WHEN u.Reputation BETWEEN 100 AND 999 THEN 'Emerging' 
            ELSE 'Newcomer' 
        END ORDER BY u.Reputation DESC) AS ReputationCategoryRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
        FROM Votes 
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    GROUP BY u.Id, u.DisplayName
),
HighVotePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS LinkCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- considering only up/down votes
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '><')) AS TagName -- splitting tags
    ) t ON true
    WHERE p.Score > (SELECT AVG(Score) FROM Posts)
    GROUP BY p.Id, p.Title
    HAVING COUNT(DISTINCT v.UserId) > 5
),
CombinedResults AS (
    SELECT 
        uvs.UserId,
        uvs.DisplayName,
        uvs.ReputationCategoryRank,
        hpp.PostId,
        hpp.Title,
        hpp.UniqueVoteCount,
        hpp.AssociatedTags,
        hpp.CommentCount,
        hpp.LinkCount
    FROM UserVoteStatistics uvs
    JOIN HighVotePosts hpp ON uvs.PostsCreated > 0
    ORDER BY uvs.TotalPositiveVotes DESC, hpp.UniqueVoteCount DESC
)
SELECT 
    *,
    CASE 
        WHEN ReputationCategoryRank = 1 THEN 'High Reputation User'
        WHEN ReputationCategoryRank = 2 THEN 'Moderate Reputation User'
        ELSE 'Low Reputation User'
    END AS UserCategory
FROM CombinedResults
WHERE UserCategory IS NOT NULL
AND (UniqueVoteCount > 10 OR CommentCount > 15) -- arbitrary complexity
ORDER BY UserId, PostId;
