WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name IN ('Question', 'Answer')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10 -- Consider tags used in more than 10 posts
),
FinalRanking AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.Score,
        r.CommentCount,
        ra.LastEditDate,
        ra.CloseCount,
        CASE 
            WHEN ra.CloseCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS Status,
        ARRAY(SELECT pt.TagName FROM PopularTags pt WHERE pt.TagUsageCount >= 5) AS PopularTags
    FROM 
        RankedPosts r
    JOIN 
        RecentActivity ra ON r.PostId = ra.PostId
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerDisplayName,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.LastEditDate,
    fr.Status,
    COALESCE(STRING_AGG(DISTINCT pt.TagName, ', '), 'No Tags') AS Tags
FROM 
    FinalRanking fr
LEFT JOIN 
    LATERAL unnest(fr.PopularTags) AS pt(TagName) ON TRUE
WHERE 
    fr.Score > 5 -- filtering for posts with a good score
GROUP BY 
    fr.PostId, fr.Title, fr.OwnerDisplayName, fr.CreationDate, fr.Score, 
    fr.CommentCount, fr.LastEditDate, fr.Status
ORDER BY 
    fr.Score DESC, fr.CommentCount DESC;
