WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other' 
        END ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
FilteredPosts AS (
    SELECT 
        *,
        (CAST(UpVoteCount AS FLOAT) / NULLIF((UpVoteCount + DownVoteCount), 0)) * 100 AS UpVotePercentage
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    FORMAT(fp.CreationDate, 'yyyy-MM-dd') AS CreationDate,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UpVotePercentage,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT 
        p.Id AS PostId, 
        STRING_AGG(t.TagName, ', ') AS TagName
     FROM 
        Posts p
     JOIN 
        STRING_SPLIT(p.Tags, ',') AS tag_split ON tag_split.value = CAST(t.Id AS VARCHAR)
     JOIN 
        Tags t ON t.TagName = tag_split.value
     GROUP BY 
        p.Id) t ON fp.PostId = t.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, 
    fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount, fp.UpVotePercentage
ORDER BY 
    fp.UpVoteCount DESC;
