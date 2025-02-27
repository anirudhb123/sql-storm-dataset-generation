WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, 1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 1
    UNION ALL
    SELECT t.Id, t.TagName, r.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.WikiPostId = r.Id
),
TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 1000
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM Posts p
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) AND p.ViewCount > 100
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Votes v
    GROUP BY v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS Count
    FROM PostHistory ph
    WHERE ph.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
CombinedData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ps.UpVotesCount,
        ps.DownVotesCount,
        p.Score,
        phs.Count AS HistoryCount,
        tu.DisplayName AS TopUser
    FROM Posts p
    LEFT JOIN VotesSummary ps ON p.Id = ps.PostId
    LEFT JOIN PostHistorySummary phs ON p.Id = phs.PostId
    LEFT JOIN TopUsers tu ON p.OwnerUserId = tu.Id
    WHERE p.PostTypeId = 1 -- Only questions
     AND (ps.UpVotesCount - ps.DownVotesCount) > 10 -- Positive score
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount, 
    cd.UpVotesCount,
    cd.DownVotesCount,
    cd.Score,
    cd.HistoryCount,
    cd.TopUser,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     INNER JOIN Posts p ON p.Id = cd.PostId 
     WHERE p.Tags LIKE '%' + t.TagName + '%') AS RelatedTags
FROM CombinedData cd
WHERE cd.HistoryCount >= 2 -- At least 2 changes in history
ORDER BY cd.ViewCount DESC, cd.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Top 10 results
