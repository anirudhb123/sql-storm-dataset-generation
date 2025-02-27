WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- Get most recent post per tag
),
TopTagPosts AS (
    SELECT 
        Tags,
        COUNT(*) AS TagPostCount,
        SUM(Score) AS TotalScore
    FROM 
        FilteredPosts
    GROUP BY 
        Tags
    ORDER BY 
        TagPostCount DESC
    LIMIT 10 -- Get top 10 tags by post count
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    tt.Tags,
    tt.TagPostCount,
    tt.TotalScore
FROM 
    FilteredPosts f
JOIN 
    TopTagPosts tt ON f.Tags = tt.Tags
ORDER BY 
    tt.TotalScore DESC, f.CreationDate DESC;

