
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS UniqueTags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON FIND_IN_SET(t.TagName, REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', ',')) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Title, p.Body
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        VoteCount,
        UniqueTags
    FROM 
        RankedPosts
    WHERE 
        RN = 1 
)
SELECT 
    fp.OwnerDisplayName,
    COUNT(fp.PostId) AS QuestionCount,
    SUM(fp.VoteCount) AS TotalVotes,
    GROUP_CONCAT(fp.Title SEPARATOR '; ') AS QuestionTitles,
    GROUP_CONCAT(DISTINCT tag ORDER BY tag SEPARATOR ', ') AS AllUniqueTags
FROM 
    FilteredPosts fp,
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(fp.UniqueTags, ',', n.n), ',', -1) AS tag
     FROM 
        (SELECT @row := @row + 1 AS n FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n1,
         (SELECT @row := 0) n2) n) AS n
WHERE 
    n.n <= 1 + (LENGTH(fp.UniqueTags) - LENGTH(REPLACE(fp.UniqueTags, ',', '')))
GROUP BY 
    fp.OwnerDisplayName
ORDER BY 
    TotalVotes DESC
LIMIT 10;
