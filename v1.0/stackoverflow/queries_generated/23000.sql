WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS OwnerPostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(CASE WHEN p.PostTypeId IN (2, 3) THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '90 days'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    au.DisplayName AS OwnerDisplayName,
    au.Reputation AS OwnerReputation,
    rp.OwnerPostCount,
    COALESCE(rv.VoteCount, 0) AS RecentVotes,
    CASE WHEN rp.Score > 10 THEN 'Popular' ELSE 'Needs attention' END AS PostStatus,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))::int[])) 
     GROUP BY t.Id) AS AssociatedTags,
    CASE 
        WHEN EXISTS (SELECT 1 
                     FROM PostHistory ph 
                     WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)) 
        THEN 'Has closure history' 
        ELSE 'No closure history' 
    END AS ClosureStatus
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.OwnerUserId = au.UserId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.RN = 1 AND 
    rp.OwnerPostCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
