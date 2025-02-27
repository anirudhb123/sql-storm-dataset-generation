WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Question posts
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
KeywordCounts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rg.value AS Keyword,
        COUNT(*) AS KeywordCount
    FROM 
        RankedPosts rp,
        unnest(string_to_array(lower(rp.Body), ' ')) AS rg(value) -- Splitting Body into words
    WHERE 
        rg.value NOT IN ('the', 'is', 'at', 'which', 'on', 'for', 'by', 'to', 'and', 'a', 'an') -- Common stop words
    GROUP BY 
        rp.PostId, rp.Title, rg.value
),
TopKeywords AS (
    SELECT 
        PostId,
        Keyword,
        KeywordCount,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY KeywordCount DESC) AS KeywordRank
    FROM 
        KeywordCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.CreationDate,
    STRING_AGG(kw.Keyword || ': ' || kw.KeywordCount, ', ') AS TopKeywords
FROM 
    RankedPosts rp
LEFT JOIN 
    TopKeywords kw ON rp.PostId = kw.PostId AND kw.KeywordRank <= 3 -- Get top 3 keywords
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.CreationDate
ORDER BY 
    rp.ViewCount DESC
LIMIT 10; -- Limit to top 10 questions by view count
