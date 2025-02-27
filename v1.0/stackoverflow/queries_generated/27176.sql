WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.TagCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    (fp.UpVoteCount - fp.DownVoteCount) AS NetVoteScore,
    CASE 
        WHEN fp.TagCount > 5 THEN 'High Tags'
        WHEN fp.TagCount BETWEEN 3 AND 5 THEN 'Moderate Tags'
        ELSE 'Low Tags' 
    END AS TagIntensity,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseStatusChanges
FROM 
    FilteredPosts fp
ORDER BY 
    NetVoteScore DESC, 
    fp.CreationDate DESC
LIMIT 20;
