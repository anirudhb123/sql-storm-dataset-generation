WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    AND 
        p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Select top 5 ranked posts per tag
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    tt.PostId,
    tt.Title,
    tt.ViewCount,
    tt.AnswerCount,
    tt.CreationDate,
    tt.OwnerDisplayName,
    pt.TagName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    TopPosts tt
LEFT JOIN 
    Comments c ON tt.PostId = c.PostId 
LEFT JOIN 
    Votes v ON tt.PostId = v.PostId 
LEFT JOIN 
    PostTags pt ON tt.PostId = pt.PostId
LEFT JOIN 
    Badges b ON tt.OwnerDisplayName = b.UserId  -- Assuming Badges are linked to Users
GROUP BY 
    tt.PostId, tt.Title, tt.ViewCount, tt.AnswerCount, tt.CreationDate, tt.OwnerDisplayName, pt.TagName
ORDER BY 
    tt.ViewCount DESC, tt.CreationDate DESC
LIMIT 100;  -- Limit to 100 results for benchmarking
