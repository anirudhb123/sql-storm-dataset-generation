WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreatorUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.Score > (SELECT AVG(Score) FROM Posts)  -- Posts with above average score
),
PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(v.Upvotes, 0) AS Upvotes,
        COALESCE(v.Downvotes, 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, v.Upvotes, v.Downvotes
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgesCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgesCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgesCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        pw.PostId,
        pw.Title,
        pw.Upvotes,
        pw.Downvotes,
        pw.CommentCount,
        COALESCE(ub.GoldBadgesCount, 0) AS UserGoldBadges,
        COALESCE(ub.SilverBadgesCount, 0) AS UserSilverBadges,
        COALESCE(ub.BronzeBadgesCount, 0) AS UserBronzeBadges
    FROM 
        PostWithVotes pw
    LEFT JOIN Users u ON pw.Title LIKE CONCAT('%', u.DisplayName, '%')  -- Potential title mentions user display names
    LEFT JOIN UserBadges ub ON u.Id = pw.CreatorUserId
    WHERE 
        pw.CommentCount > 0 OR ub.GoldBadgesCount > 0  -- Include posts either with comments or by users with Gold badges
)
SELECT 
    PostId,
    Title,
    Upvotes,
    Downvotes,
    CommentCount,
    UserGoldBadges,
    UserSilverBadges,
    UserBronzeBadges
FROM 
    FinalResults 
WHERE 
    Upvotes - Downvotes > 0  -- Only posts with more upvotes than downvotes
ORDER BY 
    UserGoldBadges DESC, 
    Upvotes DESC
LIMIT 10;
