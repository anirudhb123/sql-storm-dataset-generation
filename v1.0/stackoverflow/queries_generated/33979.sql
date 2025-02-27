WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN LATERAL STRING_TO_ARRAY(p.Tags, '>') t ON true
    GROUP BY p.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        pw.Tags,
        COUNT(c.Id) AS CommentCount,
        pw.Title,
        pw.CreationDate,
        pw.PostId,
        pv.UpVotes,
        pv.DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC) AS PostRank
    FROM PostsWithTags pw
    LEFT JOIN Comments c ON pw.PostId = c.PostId
    JOIN PostVoteCounts pv ON pw.PostId = pv.PostId
    WHERE pw.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY pw.PostId, pw.Title, pw.CreationDate, pw.Tags, pv.UpVotes, pv.DownVotes
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.PostRank
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE ub.TotalBadges IS NOT NULL OR rp.PostId IS NOT NULL
ORDER BY rp.PostRank, u.Reputation DESC
LIMIT 100;
