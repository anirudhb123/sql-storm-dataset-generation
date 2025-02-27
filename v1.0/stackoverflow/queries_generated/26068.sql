WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        p.Score,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag(TagName) ON true
    WHERE p.CreationDate >= NOW() - INTERVAL '3 months'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.Score,
        rp.Tags
    FROM RankedPosts rp
    WHERE rp.UserRank <= 3
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS NumberOfPosts,
        SUM(b.class = 1) AS GoldBadges,
        SUM(b.class = 2) AS SilverBadges,
        SUM(b.class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
    HAVING u.Reputation > 1000
),
FinalResults AS (
    SELECT 
        tr.PostId,
        tr.Title,
        tr.Body,
        tr.CommentCount,
        tr.Score,
        ARRAY_TO_STRING(tr.Tags, ', ') AS Tags,
        ur.DisplayName AS UserName,
        ur.Reputation AS UserReputation,
        ur.NumberOfPosts,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM TopPosts tr
    JOIN UserReputation ur ON tr.UserId = ur.UserId
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.Score >= 150 THEN 'Highly Rated'
        WHEN fr.Score BETWEEN 50 AND 149 THEN 'Moderate Rating'
        ELSE 'Low Rating'
    END AS RatingCategory
FROM FinalResults fr
ORDER BY fr.Score DESC, fr.CommentCount DESC
LIMIT 50;
