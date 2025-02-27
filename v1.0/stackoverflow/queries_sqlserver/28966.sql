
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        OwnerName,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM 
    FilteredPosts fp
OUTER APPLY (SELECT 
                  value AS TagName FROM STRING_SPLIT(fp.Tags, '>')) AS t
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerName, fp.CreationDate, fp.UpVotes, fp.DownVotes, fp.CommentCount
ORDER BY 
    fp.UpVotes DESC, fp.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
