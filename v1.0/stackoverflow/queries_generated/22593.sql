WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT CASE WHEN bh.Id IS NOT NULL THEN bh.Id END) AS HistoryCount 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory bh ON bh.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.PostTypeId, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostSummary AS (
    SELECT 
        r.PostId,
        r.PostTypeId,
        r.CommentCount,
        r.UpVoteCount,
        r.DownVoteCount,
        r.HistoryCount,
        COALESCE(u.Reputation, 0) AS AuthorReputation,
        u.DisplayName AS AuthorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY r.PostTypeId ORDER BY r.UpVoteCount DESC) AS PopularityRank
    FROM 
        RecentPostStats r
    LEFT JOIN 
        Users u ON u.Id = r.OwnerUserId
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.HistoryCount,
    ps.AuthorReputation,
    ps.AuthorDisplayName,
    CASE 
        WHEN ps.PopularityRank <= 5 THEN 'Top Post'
        WHEN ps.PopularityRank <= 15 THEN 'Moderate Post'
        ELSE 'Low Popularity Post'
    END AS PopularityCategory
FROM 
    PostSummary ps 
WHERE 
    (ps.UpVoteCount - ps.DownVoteCount) > 0
    AND ps.AuthorReputation IS NOT NULL
ORDER BY 
    ps.UpVoteCount DESC, 
    ps.CommentCount DESC 
LIMIT 100;

-- Additional Query to Handle Edge Cases: Posts With No Votes or Comments
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.VoteCount, 0) AS VoteCount,
    CASE 
        WHEN c.CommentCount IS NULL AND v.VoteCount IS NULL THEN 'No Engagement'
        ELSE 'Engaged'
    END AS EngagementStatus
FROM 
    Posts p
LEFT JOIN (
    SELECT PostId, COUNT(*) AS CommentCount
    FROM Comments 
    GROUP BY PostId
) c ON c.PostId = p.Id
LEFT JOIN (
    SELECT PostId, COUNT(*) AS VoteCount
    FROM Votes 
    GROUP BY PostId
) v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
    AND p.Score > 0
ORDER BY 
    EngagementStatus DESC, 
    p.CreationDate DESC;
