WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount, -- Upvotes for post
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount -- Downvotes for post
    FROM Posts p
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM PostHistory ph
    WHERE ph.CreationDate BETWEEN NOW() - INTERVAL '30 days' AND NOW()
    AND ph.PostHistoryTypeId IN (10, 11, 12)
),
FinalResults AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        us.TotalPosts,
        us.TotalComments,
        us.Reputation,
        us.GoldBadges,
        up.PostId,
        up.Title,
        up.CreationDate,
        r.UpVoteCount,
        r.DownVoteCount,
        a.ActivityRank
    FROM UserStatistics us
    JOIN RankedPosts r ON r.PostId = (
        SELECT rp.PostId 
        FROM RankedPosts rp 
        WHERE rp.rn = 1
        AND rp.PostTypeId IN (1, 2) -- Only Questions and Answers
        ORDER BY r.CreationDate DESC
        LIMIT 1
    ) 
    JOIN Comments c ON us.UserId = c.UserId
    JOIN PostActivity a ON a.PostId = r.PostId
    WHERE r.rn = 1
)

SELECT 
    fr.DisplayName,
    fr.TotalPosts,
    fr.TotalComments,
    fr.Reputation,
    fr.GoldBadges,
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    CASE 
        WHEN fr.UpVoteCount > fr.DownVoteCount THEN 'More Upvotes'
        WHEN fr.UpVoteCount < fr.DownVoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteStatus,
    COALESCE(a.ActivityRank, 0) AS RecentActivityRank
FROM FinalResults fr
LEFT JOIN PostActivity a ON fr.PostId = a.PostId
ORDER BY fr.Reputation DESC, fr.PostId;
