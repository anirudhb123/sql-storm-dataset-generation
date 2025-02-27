WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Get only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created within the last year
), CloseStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonsCount,
        STRING_AGG(crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only consider close and reopen history
    GROUP BY 
        ph.PostId
), TopTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1 -- Only consider the most recent posts per tag
)
SELECT 
    rp.Title AS QuestionTitle,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ct.CloseReasonsCount,
    ct.CloseReasons,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseStats ct ON rp.PostId = ct.PostId
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
LIMIT 10;
