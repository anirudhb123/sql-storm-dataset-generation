WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate
), 
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Trim(Both '<>' FROM Tags), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.AnswerCount,
    rp.VoteCount,
    tt.TagName,
    tt.PostCount AS TagPostCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%' 
WHERE 
    rp.rn = 1 -- Only the latest edit
ORDER BY 
    rp.VoteCount DESC, rp.CreationDate DESC
LIMIT 10;
