WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '>')) AS tag_name ON true
    LEFT JOIN Tags t ON t.TagName = tag_name
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ps.TotalPosts,
        ps.TotalComments,
        ps.UpVotes,
        ps.DownVotes,
        ps.GoldBadges,
        ps.SilverBadges,
        ps.BronzeBadges
    FROM PostScore p
    JOIN UserStats ps ON p.OwnerDisplayName = ps.DisplayName
    ORDER BY p.Score DESC, p.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.TotalPosts,
    tp.TotalComments,
    tp.UpVotes,
    tp.DownVotes,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    string_agg(DISTINCT t.TagName, ', ') AS Tags
FROM TopPosts tp
LEFT JOIN LATERAL unnest(string_to_array(tp.Tags::text, ', ')) AS t(TagName) ON true
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.TotalPosts, tp.TotalComments, tp.UpVotes, tp.DownVotes, tp.GoldBadges, tp.SilverBadges, tp.BronzeBadges
ORDER BY tp.Score DESC;
