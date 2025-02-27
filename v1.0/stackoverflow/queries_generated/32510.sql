WITH RecursiveTagCTE AS (
    SELECT 
        Id,
        TagName,
        Count,
        1 AS RecursionLevel
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0
  
    UNION ALL
  
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        rtc.RecursionLevel + 1
    FROM 
        Tags t
    JOIN 
        RecursiveTagCTE rtc ON t.Count > 0 AND t.Id <> rtc.Id
),
UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT
    ud.UserId,
    ud.DisplayName,
    ud.Reputation,
    p.Title,
    p.Score,
    ph.EditCount,
    ph.LastEdited,
    COALESCE(pt.TagName, 'No Tag') AS MostUsedTag,
    CASE 
        WHEN ud.Reputation >= 10000 THEN 'Top Contributor'
        WHEN ud.Reputation >= 5000 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserLevel,
    COALESCE(pt.Count, 0) AS TagCount
FROM 
    UserReputationCTE ud
JOIN 
    Posts p ON p.OwnerUserId = ud.UserId
LEFT JOIN 
    (SELECT DISTINCT ON (p.Id) t.TagName, t.Count 
        FROM Tags t
        JOIN Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
        ORDER BY t.Count DESC) pt ON p.Id = pt.Id
LEFT JOIN 
    PostHistoryAggregate ph ON p.Id = ph.PostId
WHERE 
    ph.EditCount > 1 
ORDER BY 
    ud.Reputation DESC, p.Score DESC
LIMIT 100;
