WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagsArray,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PostTagCount AS (
    SELECT 
        tag, 
        COUNT(*) AS PostCount
    FROM 
        ProcessedPosts, 
        unnest(TagsArray) AS tag
    GROUP BY 
        tag
),
TopTags AS (
    SELECT 
        tag, 
        PostCount
    FROM 
        PostTagCount
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
AllPostDetails AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Body,
        pp.CreationDate,
        pp.ViewCount,
        pp.AnswerCount,
        pp.OwnerDisplayName,
        pp.Upvotes,
        pp.Downvotes,
        ARRAY(SELECT tag FROM unnest(pp.TagsArray) AS tag) AS Tags
    FROM 
        ProcessedPosts pp
)

SELECT 
    apd.PostId,
    apd.Title,
    apd.Body,
    apd.CreationDate,
    apd.ViewCount,
    apd.AnswerCount,
    apd.OwnerDisplayName,
    apd.Upvotes,
    apd.Downvotes,
    ARRAY_REMOVE(ARRAY(SELECT t.tag FROM TopTags t WHERE t.tag = ANY(apd.Tags)), NULL) AS TopTags
FROM 
    AllPostDetails apd
ORDER BY 
    apd.ViewCount DESC, 
    apd.Upvotes DESC
LIMIT 10;
