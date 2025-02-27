WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        Coalesce(ExcerptPostId, 0) AS ExcerptPostId,
        Coalesce(WikiPostId, 0) AS WikiPostId,
        1 AS Level
    FROM Tags
    
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        Coalesce(t.ExcerptPostId, 0),
        Coalesce(t.WikiPostId, 0),
        rh.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rh ON t.ExcerptPostId = rh.Id
)

, PostVoteAggregation AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
)

, PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AuthorUserId,
        COALESCE(ag.UpVotes, 0) AS UpVotes,
        COALESCE(ag.DownVotes, 0) AS DownVotes,
        COALESCE(ag.TotalVotes, 0) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ag.TotalVotes, 0) DESC, p.CreationDate) AS Rank
    FROM Posts p
    LEFT JOIN PostVoteAggregation ag ON p.Id = ag.PostId
    WHERE p.PostTypeId = 1
)

, PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.RevisionGUID,
        ph.CreationDate,
        p.Title AS PostTitle,
        pt.Name AS PostTypeName,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    pp.Id AS PostId,
    pp.Title,
    pp.UpVotes,
    pp.DownVotes,
    pp.TotalVotes,
    COUNT(DISTINCT ph.PostId) AS HistoryCount,
    MAX(ph.CreationDate) AS LastEditDate,
    STRING_AGG(DISTINCT rh.TagName, ', ') AS RelatedTags
FROM PopularPosts pp
LEFT JOIN PostHistoryDetails ph ON pp.Id = ph.PostId
LEFT JOIN RecursiveTagHierarchy rh ON pp.Id = rh.ExcerptPostId
WHERE pp.Rank <= 10
GROUP BY pp.Id, pp.Title, pp.UpVotes, pp.DownVotes, pp.TotalVotes
ORDER BY pp.TotalVotes DESC;
