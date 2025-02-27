WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
), 

PostMetrics AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        ViewCount,
        AnswerCount,
        OwnerName,
        Rank,
        COALESCE(pht1.Comment, 'No Close Reason') AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        CloseReasonTypes pht1 ON ph.Comment = CAST(pht1.Id AS VARCHAR)
    WHERE 
        Rank <= 5 -- Top 5 posts by score for each type
),

UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges 
    GROUP BY 
        UserId
),

UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        (u.UpVotes - u.DownVotes) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)

SELECT 
    pm.Title,
    pm.Score,
    pm.OwnerName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pm.CloseReason
FROM 
    PostMetrics pm
JOIN 
    UserScore us ON pm.OwnerName = us.DisplayName
ORDER BY 
    pm.Score DESC;
