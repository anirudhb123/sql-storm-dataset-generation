WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        SUM(v.BountyAmount) AS TotalBounties,
        COALESCE(NULLIF(AVG(u.Reputation), 0), 1) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty related votes
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.CommentCount,
    RP.Rank,
    RP.TotalBounties,
    RP.AvgUserReputation,
    PH.Comment,
    PH.CreationDate AS HistoryCreationDate,
    CASE 
        WHEN RP.CommentCount > 10 THEN 'Highly Engaged'
        WHEN RP.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    RankedPosts RP
LEFT JOIN 
    (SELECT DISTINCT p.Id, ph.Comment, ph.CreationDate
     FROM Posts p
     JOIN PostHistory ph ON p.Id = ph.PostId
     WHERE ph.PostHistoryTypeId IN (10, 11, 12)   -- Closed, Reopened, or Deleted
     AND ph.CreationDate >= NOW() - INTERVAL '6 months') PH ON RP.PostId = PH.Id
WHERE 
    RP.Rank <= 3 -- Filtering for top 3 posts per user
    OR RP.TotalBounties > 0 -- Including posts with bounties
ORDER BY 
    RP.AvgUserReputation DESC, 
    RP.ViewCount DESC
LIMIT 50;

-- A union to show post linkages to other related posts containing bizarre semantics
UNION ALL

SELECT 
    pl.PostId,
    CONCAT('Post ID: ', pl.PostId, ' linked to Post ID: ', pl.RelatedPostId) AS Title,
    pl.CreationDate,
    NULL AS ViewCount,
    NULL AS CommentCount,
    NULL AS Rank,
    NULL AS TotalBounties,
    NULL AS AvgUserReputation,
    NULL AS Comment,
    NULL AS HistoryCreationDate,
    'Linked Post' AS EngagementLevel
FROM 
    PostLinks pl
WHERE 
    pl.LinkTypeId = 1 -- Marking only direct links
    AND NOT EXISTS (
        SELECT 1 FROM Posts p 
        WHERE p.Id = pl.RelatedPostId 
        AND p.Score IS NULL -- Unusual finding posts with no score
    )
ORDER BY 
    pl.CreationDate DESC
LIMIT 30;
