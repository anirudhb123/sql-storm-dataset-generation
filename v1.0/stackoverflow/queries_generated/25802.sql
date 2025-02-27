WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
TopTags AS (
    SELECT
        UNNEST(string_to_array(Tags, '>')) AS Tag
    FROM
        Posts
    WHERE
        PostTypeId = 1
)
SELECT
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Tags,
    tt.Tag,
    COUNT(*) AS TagFrequency
FROM
    RankedPosts rp
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, '>'))
WHERE
    rp.TagRank <= 5 -- Keeping only the latest posts per tag
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.AnswerCount, rp.Tags, tt.Tag
ORDER BY
    TagFrequency DESC,
    rp.CreationDate DESC;
