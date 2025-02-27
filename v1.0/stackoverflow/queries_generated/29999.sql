WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, U.DisplayName
),

TagStatistics AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) ) AS TagName,
        COUNT(p.Id) AS TagCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        TagName
)

SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.Body,
    rp.AnswerCount,
    rp.CommentCount,
    ts.TagName,
    ts.TagCount,
    ts.AvgViewCount,
    ts.AvgAnswerCount
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.TagName = ANY(STRING_TO_ARRAY(rp.Tags, '>')) 
WHERE 
    rp.PostRank = 1 -- Get the most recent post by each user
ORDER BY 
    rp.OwnerDisplayName, ts.TagCount DESC;
