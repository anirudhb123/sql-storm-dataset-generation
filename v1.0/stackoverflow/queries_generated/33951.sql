WITH RecursivePostHierarchy AS (
    SELECT Id, ParentId, Title, CreationDate, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, ph.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
PostScoreWithBadges AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT CASE WHEN bt.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN bt.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(DISTINCT CASE WHEN bt.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN BadgesTypes bt ON b.Class = bt.Id
    GROUP BY p.Id, p.Title, p.CreationDate, u.Reputation
),
PopularComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentsText
    FROM Comments c
    GROUP BY c.PostId
),
FinalRanking AS (
    SELECT
        psh.Id AS PostId,
        psh.Title,
        psh.CreationDate,
        psh.Score,
        ps.BadgeCount,
        ps.GoldBadges,
        ps.SilverBadges,
        ps.BronzeBadges,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.CommentsText, '') AS CommentsText,
        ROW_NUMBER() OVER (ORDER BY psh.Score DESC, ps.BadgeCount DESC) AS Rank
    FROM RecursivePostHierarchy psh
    LEFT JOIN PostScoreWithBadges ps ON psh.Id = ps.PostId
    LEFT JOIN PopularComments pc ON psh.Id = pc.PostId
),
TopPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Score > 100 THEN 'Highly Rated'
            WHEN Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
            ELSE 'Low Rated' 
        END AS RatingCategory
    FROM FinalRanking
    WHERE Rank <= 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.BadgeCount,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    tp.CommentCount,
    tp.CommentsText,
    tp.RatingCategory
FROM TopPosts tp
ORDER BY tp.Rank, tp.Score DESC;
