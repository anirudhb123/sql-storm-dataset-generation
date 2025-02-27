WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        COALESCE(CAST(NULLIF(SUBSTRING(p.Body, 1, 50), '') AS VARCHAR(50)), '<No Content>') AS ShortBody
    FROM
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerRank,
        rp.VoteCount,
        CASE 
            WHEN rp.ViewCount IS NULL THEN '<No Views>'
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
            ELSE 'Moderately Viewed'
        END AS ViewCategory,
        NULLIF(rp.ShortBody, '<No Content>') AS BodySnippet
    FROM
        RankedPosts rp
    WHERE
        rp.OwnerRank = 1
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.ViewCategory,
    fp.BodySnippet,
    COALESCE(PHD.ChangeCount, 0) AS TotalEdits,
    (SELECT STRING_AGG(CONCAT_WS(': ', pt.Name, COUNT(p.Id)), ', ')
     FROM PostTypes pt 
     LEFT JOIN Posts p ON pt.Id = p.PostTypeId 
     WHERE p.OwnerUserId = fp.PostId) AS RelatedPostTypes
FROM
    FilteredPosts fp
    LEFT JOIN PostHistoryDetails PHD ON fp.PostId = PHD.PostId
WHERE
    fp.ViewCategory = 'Highly Viewed'
ORDER BY
    fp.Score DESC NULLS LAST, 
    fp.ViewCount DESC, 
    fp.Title ASC;
