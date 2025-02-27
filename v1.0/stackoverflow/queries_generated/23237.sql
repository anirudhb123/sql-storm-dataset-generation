WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS TotalDownVotes,
        ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL) OVER (PARTITION BY p.Id) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tagName) 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

ExcessivePostUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN (p.ViewCount IS NULL OR p.ViewCount = 0) THEN 1 ELSE 0 END) AS ZeroViewCountPosts
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 10 AND SUM(CASE WHEN (p.ViewCount IS NULL OR p.ViewCount = 0) THEN 1 ELSE 0 END) > 2
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(ph.Comment) AS PostHistoryComments,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        MIN(ph.CreationDate) AS FirstHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount,
    eu.OwnerUserId,
    eu.PostCount,
    eu.ZeroViewCountPosts,
    phd.PostHistoryComments,
    phd.CloseReopenCount,
    phd.FirstHistoryDate,
    rp.TagsArray,
    CASE
        WHEN rp.TotalUpVotes > rp.TotalDownVotes THEN 'Positive'
        WHEN rp.TotalDownVotes > rp.TotalUpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    RankedPosts rp
JOIN 
    ExcessivePostUsers eu ON rp.OwnerUserId = eu.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
