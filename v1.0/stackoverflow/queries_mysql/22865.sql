
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        CreationDate,
        COALESCE(LastAccessDate, CreationDate) AS LastActiveDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
    HAVING 
        COUNT(v.Id) > 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 60 DAY
),
TopTags AS (
    SELECT 
        t.TagName,
        t.Count,
        DENSE_RANK() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.Count >= 100
)
SELECT 
    ur.UserId,
    ur.Reputation,
    pp.Title,
    pp.CreationDate AS PostDate,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    COALESCE(rph.UserDisplayName, 'No recent history') AS LastEditor,
    rph.CreationDate AS LastEditedDate,
    tt.TagName,
    pp.Score,
    CASE 
        WHEN pp.Score > 10 THEN 'High Score' 
        WHEN pp.Score BETWEEN 1 AND 10 THEN 'Medium Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    UserReputation ur
JOIN 
    PopularPosts pp ON ur.UserId = pp.OwnerUserId
LEFT JOIN 
    RecentPostHistory rph ON pp.PostId = rph.PostId AND rph.RecentHistory = 1
LEFT JOIN 
    PostLinks pl ON pp.PostId = pl.PostId
LEFT JOIN 
    Tags tt ON pl.RelatedPostId = tt.WikiPostId
WHERE 
    (rph.CreationDate IS NULL OR rph.CreationDate > '2024-10-01 12:34:56' - INTERVAL 7 DAY)
ORDER BY 
    ur.Reputation DESC,
    pp.CommentCount DESC,
    pp.Score DESC
LIMIT 100;
