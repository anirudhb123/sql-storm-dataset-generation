WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, WikiPostId, 0 AS Level
    FROM Tags 
    WHERE Count > 0 -- Start with tags that have at least one question

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.WikiPostId, r.Level + 1
    FROM Tags t
    JOIN RecursiveTagHierarchy r ON t.Id = r.WikiPostId 
    WHERE r.Level < 5 -- limit the depth of recursion
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
), 

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes -- Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId 
    GROUP BY p.Id
), 

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate > NOW() - INTERVAL '30 days'
)

SELECT 
    u.DisplayName AS User,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.AnswerCount AS TotalAnswers,
    ph.PostHistoryTypeId AS LastHistoryAction,
    CASE 
        WHEN ph.PostHistoryTypeId IS NOT NULL THEN 
            'Edited on ' || to_char(ph.CreationDate, 'YYYY-MM-DD HH24:MI')
        ELSE 
            'No recent edits'
    END AS LastActionDate,
    rt.TagName,
    rt.Count AS TagCount,
    ur.Reputation AS UserReputation,
    ur.Rank AS UserRank,
    p.UpVotes,
    p.DownVotes,
    p.ViewCount,
    CASE WHEN p.ViewCount > 100 THEN 'Popular' ELSE 'Less Popular' END AS Popularity
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN RecentPostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
LEFT JOIN PostStats pStats ON p.Id = pStats.PostId
LEFT JOIN RecursiveTagHierarchy rt ON p.Tags LIKE '%' || rt.TagName || '%'
JOIN UserReputation ur ON u.Id = ur.UserId
WHERE p.CreationDate > NOW() - INTERVAL '1 year'
AND (p.PostTypeId IN (1, 2) OR p.AcceptedAnswerId IS NOT NULL)
AND (p.Status = 0 OR pStatus IS NULL)
ORDER BY ur.Reputation DESC, p.Score DESC, rt.Count DESC
FETCH FIRST 100 ROWS ONLY;
