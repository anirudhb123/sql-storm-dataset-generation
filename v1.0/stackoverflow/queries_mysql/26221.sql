
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        rp.VoteCount > 10 AND 
        rp.CommentCount > 5
),
FinalOutput AS (
    SELECT 
        fp.*,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS RelatedTags,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', numbers.n), '><', -1) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE numbers.n <= CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '><', '')) + 1) AS tag
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
    LEFT JOIN 
        PostLinks pl ON fp.PostId = pl.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.OwnerDisplayName, fp.CommentCount, fp.VoteCount
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CommentCount,
    f.VoteCount,
    f.RelatedTags,
    f.RelatedPostCount,
    f.CreationDate
FROM 
    FinalOutput f
ORDER BY 
    f.VoteCount DESC, f.CommentCount DESC;
