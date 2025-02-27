
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        @row_num := IF(@prev_val = YEAR(p.CreationDate), @row_num + 1, 1) AS PopularityRank,
        @prev_val := YEAR(p.CreationDate)
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id,
        (SELECT @row_num := 0, @prev_val := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        GROUP_CONCAT(DISTINCT crt.Name ORDER BY crt.Name ASC SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    INNER JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS SIGNED) = crt.Id
    WHERE 
        pht.Name LIKE '%Closed%'
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    ubc.UserId,
    ubc.DisplayName,
    ubc.Reputation,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    pq.Title AS PopularQuestionTitle,
    pq.CreationDate AS PopularQuestionDate,
    pq.Score AS PopularQuestionScore,
    cp.CloseReasons AS ClosedPostReasons
FROM 
    UserBadgeCounts ubc
LEFT JOIN 
    PopularQuestions pq ON ubc.UserId = (
        SELECT 
            p.OwnerUserId
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1 
            AND p.Score > 0
        ORDER BY 
            p.ViewCount DESC
        LIMIT 1
    )
LEFT JOIN 
    ClosedPosts cp ON pq.PostId = cp.PostId
WHERE 
    ubc.Reputation > 1000
ORDER BY 
    ubc.Reputation DESC,
    pq.Score DESC;
