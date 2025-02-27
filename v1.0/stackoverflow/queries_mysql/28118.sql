
WITH StringData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(clr.Name, 'Not Closed') AS CloseReason,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsString
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        CloseReasonTypes clr ON CAST(ph.Comment AS UNSIGNED) = clr.Id
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', nums.n), '><', -1) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) nums
         CROSS JOIN Posts p
         WHERE CHAR_LENGTH(p.Tags) > 2) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, clr.Name
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    TagsString,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    CloseReason,
    CASE 
        WHEN CHAR_LENGTH(Body) > 500 THEN 'Long Body' 
        ELSE 'Short Body' 
    END AS BodyLengthCategory,
    TIMESTAMPDIFF(SECOND, CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds
FROM 
    StringData
ORDER BY 
    AgeInSeconds DESC
LIMIT 10;
