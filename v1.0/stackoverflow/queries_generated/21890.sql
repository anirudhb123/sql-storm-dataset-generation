WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.UpVotes DESC) AS PostRank
    FROM 
        RecentPosts rp
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    ud.TotalReputation,
    ud.BadgeCount,
    (CASE 
        WHEN pd.DownVotes > pd.UpVotes THEN 'Negative' 
        WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
        ELSE 'Neutral' 
     END) AS VoteSentiment,
    (SELECT string_agg(tag.TagName, ', ') 
     FROM Tags tag 
     WHERE tag.Id IN (
         SELECT unnest(string_to_array(p.Tags, '><'))::int
     )) AS AssociatedTags
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.PostId = u.Id
LEFT JOIN 
    UserReputation ud ON u.Id = ud.UserId
WHERE 
    pd.PostRank <= 10
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC;

-- Additional edge case with handling NULL logic and bizarre semantics
UNION ALL
SELECT 
    'Total Users with Zero Reputation' AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS UpVotes,
    NULL AS DownVotes,
    NULL AS CommentCount,
    COUNT(*) AS TotalWithZeroReputation,
    NULL AS BadgeCount,
    'Neutral' AS VoteSentiment,
    NULL AS AssociatedTags
FROM 
    Users 
WHERE 
    Reputation IS NULL
GROUP BY 
    Reputation;

-- Catch-all for unknown semantics of Post IDs
SELECT 
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS UpVotes,
    NULL AS DownVotes,
    NULL AS CommentCount,
    'Undefined' AS TotalReputation,
    'Unlimited' AS BadgeCount,
    'Undefined' AS VoteSentiment,
    STRING_AGG(DISTINCT CASE WHEN (p.Id < 0) THEN 'Negative IDs' ELSE 'Valid IDs' END, ', ') AS AssociatedTags
FROM 
    Posts p
WHERE 
    p.Id < 0
GROUP BY 
    p.Id;

