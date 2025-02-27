
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AcceptedAnswerId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT a.N + 1 as n FROM (SELECT 0 as N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n
        ON n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName, 
        COUNT(*) AS Frequency
    FROM 
        Posts
    JOIN 
        (SELECT a.N + 1 as n FROM (SELECT 0 as N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n
        ON n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        Frequency DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.Frequency
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '><', -1)
JOIN 
    (SELECT a.N + 1 as n FROM (SELECT 0 as N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n
    ON n.n <= CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) + 1
WHERE 
    rp.TagRank <= 5
ORDER BY 
    pt.Frequency DESC, 
    rp.CreationDate DESC;
