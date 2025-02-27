WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), '1970-01-01') AS ClosedDate,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 52 THEN ph.CreationDate END), '1970-01-01') AS HotQuestionDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.AnswerCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Tags,
        rp.ClosedDate,
        rp.HotQuestionDate,
        rp.CommentCount,
        rp.PopularityRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.ClosedDate = '1970-01-01' -- Only Open Posts
        AND rp.HotQuestionDate >= (CURRENT_DATE - INTERVAL '30 days') -- Hot within the last 30 days
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.ViewCount,
    fp.AnswerCount,
    fp.Tags,
    fp.CommentCount,
    fp.PopularityRank
FROM 
    FilteredPosts fp
ORDER BY 
    fp.PopularityRank ASC
LIMIT 10;
