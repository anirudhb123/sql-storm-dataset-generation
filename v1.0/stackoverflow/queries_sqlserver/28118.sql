
WITH StringData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(clr.Name, 'Not Closed') AS CloseReason,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        STRING_AGG(DISTINCT t.TagName) AS TagsString
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
        CloseReasonTypes clr ON TRY_CAST(ph.Comment AS INT) = clr.Id
    OUTER APPLY (
        SELECT DISTINCT tag.TagName 
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag
        LEFT JOIN Tags t ON t.TagName = tag.value
    ) AS tags
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
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
        WHEN LEN(Body) > 500 THEN 'Long Body' 
        ELSE 'Short Body' 
    END AS BodyLengthCategory,
    DATEDIFF(SECOND, CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds
FROM 
    StringData
ORDER BY 
    AgeInSeconds DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
