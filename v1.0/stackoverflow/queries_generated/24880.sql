WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.OwnerUserId, 
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.EmailHash,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        (SELECT COUNT(DISTINCT ph.PostId) FROM PostHistory ph WHERE ph.UserId = u.Id) AS HistoryCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.EmailHash
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.EmailHash,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount - tp.DownVoteCount AS NetVotes,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.HistoryCount,
    CASE 
        WHEN us.Reputation > 1000 THEN 'Experienced'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Newbie'
    END AS UserType
FROM 
    UserStats us
JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId
WHERE 
    us.EmailHash IS NOT NULL
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

-- This query finds the top 5 posts for each user by score and view count.
-- It also aggregates user statistics such as badge counts and post history.
-- The results are filtered to ensure only users with valid email hashes are considered.
-- Additional complexity includes a calculated column assessing user experience level based on their reputation.
