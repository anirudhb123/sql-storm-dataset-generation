
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, a.AcceptedAnswerId
), 
TagStatistics AS (
    SELECT 
        LOWER(TRIM(tag)) AS CleanedTag,
        COUNT(*) AS PostCount
    FROM 
        PostDetails, 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS tag
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION 
                      SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1) AS tags_table
    GROUP BY 
        LOWER(TRIM(tag))
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.CommentCount,
    pd.VoteCount,
    ts.CleanedTag,
    ts.PostCount
FROM 
    PostDetails pd
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 1 
ORDER BY 
    pd.CreationDate DESC, pd.VoteCount DESC
LIMIT 100;
