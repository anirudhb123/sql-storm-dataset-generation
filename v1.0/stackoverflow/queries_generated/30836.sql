WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Fetch only questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.AcceptedAnswerId,
        a.Score,
        a.ViewCount,
        a.AnswerCount,
        a.OwnerUserId,
        rp.Level + 1
    FROM Posts a
    INNER JOIN RecursivePosts rp ON a.ParentId = rp.Id
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    COALESCE(pvc.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pvc.Downvotes, 0) AS TotalDownvotes,
    COALESCE(pb.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(pb.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(pb.BronzeBadges, 0) AS UserBronzeBadges,
    COALESCE(pha.HistoryCount, 0) AS EditHistoryCount,
    pha.LastChangeDate
FROM RecursivePosts rp
LEFT JOIN PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN PostBadges pb ON rp.OwnerUserId = pb.UserId
LEFT JOIN PostHistoryAggregates pha ON rp.Id = pha.PostId
WHERE rp.Level = 0  -- Select questions only
  AND rp.CreationDate >= NOW() - INTERVAL '1 year'  -- Only questions created in the last year
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
