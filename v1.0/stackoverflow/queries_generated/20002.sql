WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        AVG(p2.Score) FILTER (WHERE p2.PostTypeId = 2) AS AvgAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts p2 ON p.Id = p2.ParentId  -- Join to find answers
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostClosedDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT DISTINCT
    up.DisplayName,
    rp.Title AS PostTitle,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.UpVotesCount,
    COALESCE(pd.FirstClosedDate, 'No Closures'::timestamp) AS FirstClosedDate,
    COALESCE(pd.CloseCount, 0) AS CloseOccurrences,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.AvgAnswerScore IS NULL THEN 'No Answers'
        WHEN rp.AvgAnswerScore >= 10 THEN 'High Quality'
        WHEN rp.AvgAnswerScore BETWEEN 5 AND 9 THEN 'Moderate Quality'
        ELSE 'Low Quality' 
    END AS AnswerQuality,
    CASE 
        WHEN ub.GoldBadges > 0 THEN 'Gold Member'
        WHEN ub.SilverBadges > 0 THEN 'Silver Member'
        ELSE 'Regular Member' 
    END AS MembershipStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON up.Id = rp.Id  -- Assume the post owner matches user ID
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
LEFT JOIN 
    PostClosedDetails pd ON pd.PostId = rp.Id
WHERE 
    rp.RankScore <= 10  -- Limit to top 10 posts based on score
ORDER BY 
    rp.RankScore, up.DisplayName;

