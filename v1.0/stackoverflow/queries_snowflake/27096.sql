
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS UniqueTags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.TagName IN (SELECT value FROM TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))))
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
    STRING_AGG(fp.Title, '; ') AS QuestionTitles,
    STRING_AGG(DISTINCT tag, ', ') AS AllUniqueTags
FROM 
    FilteredPosts fp,
    LATERAL FLATTEN(INPUT => fp.UniqueTags) AS tag
GROUP BY 
    fp.OwnerDisplayName
ORDER BY 
    TotalVotes DESC
LIMIT 10;
