
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
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsString
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
        CloseReasonTypes clr ON CAST(ph.Comment AS INTEGER) = clr.Id
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.VALUE
    WHERE 
        p.CreationDate >= TIMESTAMPADD(year, -1, '2024-10-01 12:34:56'::timestamp)
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
        WHEN LENGTH(Body) > 500 THEN 'Long Body' 
        ELSE 'Short Body' 
    END AS BodyLengthCategory,
    DATEDIFF(EPOCH, CreationDate, '2024-10-01 12:34:56'::timestamp) AS AgeInSeconds
FROM 
    StringData
ORDER BY 
    AgeInSeconds DESC
LIMIT 10;
