WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COALESCE(ba.Date, '1970-01-01') AS FirstBadgeDate,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges ba ON u.Id = ba.UserId
    LEFT JOIN 
        Tags t ON POSITION(CONCAT(',', t.TagName, ',') IN CONCAT(',', p.Tags, ',')) > 0
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation, ba.Date
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        COUNT(ph.Id) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FinalBenchmark AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Body,
        pp.CreationDate,
        pp.ViewCount,
        pp.Score,
        pp.OwnerDisplayName,
        pp.OwnerReputation,
        pp.FirstBadgeDate,
        pp.CommentCount,
        pp.TagList,
        pha.PostHistoryTypes,
        pha.TotalEdits,
        pha.LastEditDate
    FROM 
        ProcessedPosts pp
    LEFT JOIN 
        PostHistoryAggregation pha ON pp.PostId = pha.PostId
)
SELECT 
    *,
    CASE 
        WHEN pp.OwnerReputation > 1000 THEN 'High Reputation'
        WHEN pp.OwnerReputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    EXTRACT(DAY FROM age(NOW(), pp.CreationDate)) AS DaysSinceCreation
FROM 
    FinalBenchmark pp
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
