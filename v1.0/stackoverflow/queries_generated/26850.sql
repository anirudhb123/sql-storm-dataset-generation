WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS AgeInSeconds,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(DISTINCT pl.RelatedPostId) 
                  FROM PostLinks pl 
                  WHERE pl.PostId = p.Id AND pl.LinkTypeId = 3), 0) AS DuplicateCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Focus on Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
), 
RankedPosts AS (
    SELECT 
        fp.*,
        ROW_NUMBER() OVER (ORDER BY fp.AgeInSeconds DESC, fp.CommentCount DESC) AS PostRank
    FROM 
        FilteredPosts fp
), 
AggregatedTags AS (
    SELECT 
        string_agg(DISTINCT t.TagName, ', ') AS TagList,
        p.Id AS PostId
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.DuplicateCount,
    ag.TagList,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedTags ag ON rp.PostId = ag.PostId
WHERE 
    rp.PostRank <= 10 -- Get top 10 questions by rank
ORDER BY 
    rp.PostRank;
