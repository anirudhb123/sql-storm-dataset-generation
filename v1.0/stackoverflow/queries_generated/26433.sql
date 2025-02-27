WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS RankWithinYear,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags 
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS TagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(TagName)
    WHERE 
        p.PostTypeId = 1  -- only questions
    GROUP BY 
        p.Id, U.DisplayName 
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 4) AS TimesTitleEdited,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 5) AS TimesBodyEdited,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS TimesClosed
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    rp.AnswerCount,
    rp.RankWithinYear,
    ra.LastEditDate,
    ra.TimesTitleEdited,
    ra.TimesBodyEdited,
    ra.TimesClosed,
    CASE 
        WHEN ra.TimesClosed > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS Status
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.RankWithinYear <= 10  -- top 10 posts of the year 
ORDER BY 
    rp.RankWithinYear, 
    rp.Score DESC;
