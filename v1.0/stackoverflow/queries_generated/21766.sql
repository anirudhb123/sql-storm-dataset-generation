WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        MAX(CASE WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN p.CreationDate END) AS LastPostOlderThanOneYear, 
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        STRING_AGG(DISTINCT t.TagName, ', ') AS UniqueTags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    ) t ON TRUE
    WHERE u.Reputation > 0
    GROUP BY u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        STRING_AGG(pt.Name) AS PostHistoryTypeNames,
        COUNT(ph.Id) AS TotalHistoryEvents
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY ph.PostId
),
CombinedStats AS (
    SELECT 
        ups.UserId, 
        ups.DisplayName,
        ups.TotalPosts, 
        ups.Questions, 
        ups.Answers,
        ups.UpVotes,
        ups.DownVotes,
        ups.LastPostOlderThanOneYear,
        ups.PositiveScorePosts,
        ups.UniqueTags,
        COALESCE(phi.PostId, 'No History') AS RelatedPostId,
        COALESCE(phi.PostHistoryTypeNames, 'None') AS PostHistoryTypes,
        COALESCE(phi.TotalHistoryEvents, 0) AS HistoryEventCount
    FROM UserPostStats ups
    LEFT JOIN PostHistoryInfo phi ON ups.TotalPosts > 0 AND ups.UserId IN (
        SELECT OwnerUserId FROM Posts WHERE AcceptId IS NOT NULL
    )
)
SELECT 
    UserId, 
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    UpVotes,
    DownVotes,
    LastPostOlderThanOneYear,
    PositiveScorePosts,
    UniqueTags,
    RelatedPostId,
    PostHistoryTypes,
    HistoryEventCount,
    CASE 
        WHEN TotalPosts > 10 THEN 'Active Contributor'
        WHEN TotalPosts BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'New or Inactive'
    END AS ActivityLevel
FROM CombinedStats
WHERE UpVotes > DownVotes OR UniqueTags IS NOT NULL
ORDER BY TotalPosts DESC, UpVotes DESC NULLS LAST
LIMIT 50;

