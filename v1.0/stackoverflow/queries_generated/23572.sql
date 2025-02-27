WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.*,
        um.Reputation,
        um.Views,
        CONCAT('#', STRING_AGG(DISTINCT SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), ', #')) AS TagList
    FROM 
        RankedPosts rp
        JOIN Posts p ON rp.PostId = p.Id 
        JOIN UserMetrics um ON p.OwnerUserId = um.UserId 
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.PostId, um.Reputation, um.Views
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory ph 
        JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen
    GROUP BY 
        ph.PostId, ph.CreationDate
),
FinalOutput AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.Reputation,
        tp.Views,
        tp.TagList,
        COALESCE(cp.ClosedReasons, 'No Reasons Closed') AS ClosedReasons
    FROM 
        TopPosts tp
        LEFT JOIN ClosedPosts cp ON tp.PostId = cp.PostId
)
SELECT 
    *,
    CASE 
        WHEN Reputation > 1000 THEN 'Experienced User'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Intermediate User'
        ELSE 'New User'
    END AS UserExperienceLevel,
    CASE 
        WHEN Views IS NULL THEN 'No views recorded'
        ELSE CONCAT(Views, ' total views')
    END AS ViewStatistics,
    STRING_AGG(DISTINCT CASE 
        WHEN p.PostTypeId = 1 THEN 'Question' 
        WHEN p.PostTypeId = 2 THEN 'Answer' 
        ELSE 'Other' 
    END, ', ') AS PostTypeDescription
FROM 
    FinalOutput p
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.Reputation, p.Views, p.TagList, p.ClosedReasons;
