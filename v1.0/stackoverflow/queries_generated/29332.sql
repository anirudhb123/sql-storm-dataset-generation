WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS AuthorDisplayName,
        COUNT(a.Id) AS AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Questions from the last year
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
), RecentActivities AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' ', ph.Comment), '; ') AS ModComments,
        COUNT(*) AS ModificationCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -3, GETDATE())  -- Activities in the last 3 months
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.AuthorDisplayName,
    rp.AnswerCount,
    rp.Score,
    ra.ModComments,
    ra.ModificationCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
WHERE 
    rp.TagRank = 1  -- Only the latest post in each tag category
ORDER BY 
    rp.CreationDate DESC
OPTION (RECOMPILE);  -- Optional hint for better performance during benchmarking
