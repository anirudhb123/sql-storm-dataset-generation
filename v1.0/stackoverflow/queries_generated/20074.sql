WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName) t ON true
    WHERE 
        p.CreationDate >= '2020-01-01' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id
),
FlaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.Score < 0 AND rp.CommentCount >= 3 THEN 'Potentially Negative'
            WHEN rp.Score > 10 AND rp.UserRank = 1 THEN 'Highly Upvoted'
            ELSE 'Normal'
        END AS PostFlag
    FROM 
        RankedPosts rp
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedPostActivity AS (
    SELECT 
        pa.PostId,
        COUNT(CASE WHEN pa.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN pa.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount,
        COUNT(CASE WHEN pa.PostHistoryTypeId = 24 THEN 1 END) AS EditSuggestedCount
    FROM 
        PostActivity pa
    GROUP BY 
        pa.PostId
)

SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.PostFlag,
    COALESCE(apa.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(apa.DeletionCount, 0) AS DeletionCount,
    COALESCE(apa.EditSuggestedCount, 0) AS EditSuggestedCount,
    ARRAY_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')')) FILTER (WHERE u.Id IS NOT NULL) AS Contributors
FROM 
    FlaggedPosts fp
LEFT JOIN 
    AggregatedPostActivity apa ON fp.PostId = apa.PostId
LEFT JOIN 
    Users u ON u.Id = (SELECT DISTINCT UserId FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId IN (2, 3) LIMIT 1)
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.Score, fp.PostFlag 
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 100;
