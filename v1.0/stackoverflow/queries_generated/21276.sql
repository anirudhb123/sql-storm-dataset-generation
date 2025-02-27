WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS RankByPopularity,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment AS CloseReason,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Closed posts
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostTypeId,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(cp.CloseReason, 'Open') AS CloseReason,
    tu.DisplayName AS TopUser,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
LEFT JOIN TopUsers tu ON rp.ViewCount >= 10 -- Just an arbitrary condition for relevance
WHERE (rp.Score > 0 OR rp.ViewCount > 50) -- Only positive or popular posts
ORDER BY rp.RankByPopularity, rp.Score DESC
LIMIT 50;
This SQL query incorporates various constructs, such as common table expressions (CTEs), window functions for ranking, outer joins, and complex predicates. It retrieves a ranked list of posts from the last 30 days with their associated information about comments, votes, and specific user badge counts. Additionally, it shows if a post is closed and the associated reason if applicable, while applying arbitrary criteria to filter for top users based on popularity.
