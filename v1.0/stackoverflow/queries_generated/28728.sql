WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreateDate,
        p.Tags,
        p.OwnerUserId,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount
    FROM Posts p
    WHERE p.PostTypeId = 1 
      AND p.AnswerCount > 0 
      AND p.ViewCount > 100
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId IN (2)) AS UpVotes,
        SUM(v.VoteTypeId IN (3)) AS DownVotes
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.ViewCount,
        pa.AnswerCount,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ue.CommentCount,
        ue.UpVotes,
        ue.DownVotes
    FROM PostAnalysis pa
    JOIN UserBadges ub ON pa.OwnerUserId = ub.UserId
    JOIN UserEngagement ue ON pa.OwnerUserId = ue.UserId
    ORDER BY pa.ViewCount DESC, pa.AnswerCount DESC
    LIMIT 10
)

SELECT 
    p.Title,
    p.ViewCount,
    p.AnswerCount,
    p.TotalBadges,
    p.GoldBadges,
    p.SilverBadges,
    p.BronzeBadges,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS TagList
FROM TopPosts p
LEFT JOIN (
    SELECT 
        pt.PostId,
        t.TagName
    FROM Posts pt
    CROSS JOIN LATERAL string_to_array(substring(pt.Tags, 2, length(pt.Tags)-2), '><') AS tagname
    JOIN Tags t ON tagname = t.TagName
) tag ON p.PostId = tag.PostId
GROUP BY p.Title, p.ViewCount, p.AnswerCount, p.TotalBadges, p.GoldBadges, p.SilverBadges, p.BronzeBadges, p.CommentCount, p.UpVotes, p.DownVotes
ORDER BY p.ViewCount DESC;
