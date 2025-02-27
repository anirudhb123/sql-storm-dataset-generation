WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CreationDate,
        rp.OwnerName,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1  -- keep only top-ranked posts for each tag
        AND rp.ViewCount > 100  -- only posts with over 100 views
    ORDER BY 
        rp.ViewCount DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CreationDate,
    fp.OwnerName,
    fp.CommentCount,
    fp.Tags,
    EXTRACT(YEAR FROM fp.CreationDate) AS YearCreated
FROM 
    FilteredPosts fp
WHERE 
    fp.CreationDate >= NOW() - INTERVAL '1 year'  -- posts created in the last year
ORDER BY 
    fp.ViewCount DESC, 
    fp.CommentCount DESC;
