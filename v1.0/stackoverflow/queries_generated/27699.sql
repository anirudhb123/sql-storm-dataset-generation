WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 ranks by Tag
),
AggregateData AS (
    SELECT 
        tp.TagName,
        COUNT(tp.PostId) AS PostCount,
        SUM(tp.ViewCount) AS TotalViews,
        STRING_AGG(DISTINCT tp.Author, ', ') AS Authors
    FROM 
        TopPosts tp
    JOIN 
        LATERAL (
            SELECT 
                UNNEST(string_to_array(tp.Body, ' ')) AS TagName
            ) AS tag_extracted ON TRUE
    GROUP BY 
        tp.TagName
)
SELECT 
    ad.TagName,
    ad.PostCount,
    ad.TotalViews,
    ad.Authors,
    pg_last_update 
FROM 
    AggregateData ad
JOIN 
    (SELECT MAX(CreationDate) AS pg_last_update FROM Posts) AS last_update ON TRUE
ORDER BY 
    ad.TotalViews DESC
LIMIT 10;
