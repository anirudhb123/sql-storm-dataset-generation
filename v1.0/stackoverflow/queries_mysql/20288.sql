
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS PostRank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate > DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
        AND p.Score IS NOT NULL
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.ViewCount DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPosters AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName,
        ur.Reputation,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        ur.Reputation > (
            SELECT AVG(Reputation) FROM Users
        )
        AND rp.PostRank <= 5
),
CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        t.PostId,
        t.Title,
        t.DisplayName,
        t.Reputation,
        t.Score,
        t.ViewCount,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore,
        CASE 
            WHEN cs.AvgCommentScore > 0 THEN 'Active Discussions'
            ELSE 'No Comments Yet'
        END AS CommentStatus
    FROM 
        TopPosters t
    LEFT JOIN 
        CommentStats cs ON t.PostId = cs.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.DisplayName,
    fr.Reputation,
    fr.Score,
    fr.ViewCount,
    fr.TotalComments,
    fr.AvgCommentScore,
    fr.CommentStatus,
    CASE 
        WHEN fr.Score = (SELECT MAX(Score) FROM FinalResults) THEN 'Top Post'
        WHEN fr.Score < 0 THEN 'Negative Feedback'
        ELSE 'Moderate Post'
    END AS FeedbackStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.Reputation DESC;
