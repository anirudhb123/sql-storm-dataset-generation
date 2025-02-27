WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Only questions from the last year
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.rn = 1 -- Get the latest question for each tag
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.ViewCount
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName -- Split tags
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10 -- Top 10 tags
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    tg.TagName
FROM 
    PostStats ps
JOIN 
    TagPopularity tg ON ps.Title LIKE '%' || tg.TagName || '%' -- Join with popular tags
ORDER BY 
    ps.UpVoteCount DESC, ps.ViewCount DESC;
