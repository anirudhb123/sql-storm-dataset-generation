WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY PostId) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        r.*,
        CASE 
            WHEN r.UpVoteCount > r.DownVoteCount THEN 'Positive'
            WHEN r.UpVoteCount < r.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank <= 3
)
SELECT 
    u.DisplayName,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.Sentiment,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12)
GROUP BY 
    u.DisplayName, fp.Title, fp.Score, fp.CreationDate, fp.Sentiment
ORDER BY 
    fp.Score DESC, u.DisplayName ASC;
