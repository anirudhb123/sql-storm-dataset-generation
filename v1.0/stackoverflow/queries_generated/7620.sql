WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        c.PostId
),
TopTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),
FinalSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        COALESCE(phs.EditCount, 0) AS EditCount,
        ARRAY_AGG(DISTINCT tt.Tag) AS TopTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
    LEFT JOIN 
        TopTags tt ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || tt.Tag || '%')
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.Score,
    fs.CommentCount,
    fs.EditCount,
    fs.TopTags
FROM 
    FinalSummary fs
ORDER BY 
    fs.Score DESC, fs.CreationDate DESC;
