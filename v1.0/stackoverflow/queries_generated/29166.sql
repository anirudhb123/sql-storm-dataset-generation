WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Only consider posts from the last year
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only include Questions
    GROUP BY 
        Tag
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeletedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreatedDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Author,
    ts.Tag,
    ts.TagCount,
    phd.LastClosedDate,
    phd.LastDeletedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%<', ts.Tag, '>%')  -- Join to filter this post's tags
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 5  -- Get only the top 5 posts by type
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
