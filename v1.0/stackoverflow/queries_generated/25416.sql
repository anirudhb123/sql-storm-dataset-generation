WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    (rp.UpVotes - rp.DownVotes) AS NetScore,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS RankCategory
FROM 
    RankedPosts rp
WHERE 
    NetScore > 0  -- Only showing posts with a positive score
ORDER BY 
    NetScore DESC, 
    rp.CreationDate DESC;

