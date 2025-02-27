
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Ranking
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR 
        AND p.PostTypeId IN (1, 2) 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON p.Id = rp.PostId
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') WHERE value IS NOT NULL) AS tag
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        rp.Ranking <= 10 
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount
)
SELECT 
    fp.*,
    ROW_NUMBER() OVER (ORDER BY fp.CreationDate DESC) AS OverallRank
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;
